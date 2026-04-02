# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

class AiMatchingService
  OPENAI_URL = 'https://api.openai.com/v1/chat/completions'
  MODEL = 'gpt-4o-mini'
  TIMEOUT_SECONDS = 15

  SYSTEM_PROMPT = <<~SYSTEM.freeze
    あなたは音楽マッチングの専門家です。
    クライアントの要望と、登録されている楽曲データを照合し、最適な楽曲を推薦してください。

    以下のJSON形式で回答してください（他のテキストは含めないでください）:
    [
      {
        "track_uuid": "楽曲のUUID",
        "score": 0-100の整数,
        "reason": "推薦理由（1-2文）"
      }
    ]

    マッチ度が30以上の楽曲のみを含め、スコアの高い順に最大5件まで返してください。
  SYSTEM

  def self.call(query:)
    api_key = ENV['OPENAI_API_KEY']
    unless api_key.present?
      Rails.logger.warn("OPENAI_API_KEY が未設定のため AI マッチングをスキップします")
      return { error: 'AI機能が設定されていません' }
    end

    tracks = Track.includes(:user)
                   .where.not(bpm: nil)
                   .or(Track.where.not(genre: nil))
                   .limit(50)
                   .order(created_at: :desc)

    return { matches: [] } if tracks.empty?

    prompt = build_prompt(query: query, tracks: tracks)

    uri = URI.parse(OPENAI_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT_SECONDS
    http.read_timeout = TIMEOUT_SECONDS

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_key}"
    request.body = {
      model: MODEL,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: prompt }
      ],
      max_tokens: 500,
      temperature: 0.3
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("OpenAI API エラー (matching): #{response.code} #{response.body}")
      return { error: 'AI マッチングに失敗しました' }
    end

    body = JSON.parse(response.body)
    content = body.dig('choices', 0, 'message', 'content')&.strip

    matches = parse_matches(content, tracks)
    { matches: matches }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("OpenAI API タイムアウト (matching): #{e.message}")
    { error: 'AI マッチングがタイムアウトしました' }
  rescue JSON::ParserError => e
    Rails.logger.error("OpenAI レスポンス解析失敗 (matching): #{e.message}")
    { error: 'AI マッチング結果の解析に失敗しました' }
  rescue => e
    Rails.logger.error("AiMatchingService エラー: #{e.class} - #{e.message}")
    { error: 'AI マッチングでエラーが発生しました' }
  end

  def self.build_prompt(query:, tracks:)
    track_list = tracks.map { |t|
      line = "UUID: #{t.uuid} | タイトル: #{t.title}"
      line += " | BPM: #{t.bpm}" if t.bpm
      line += " | キー: #{t.key}" if t.key.present?
      line += " | ジャンル: #{t.genre}" if t.genre.present?
      line += " | AI説明: #{t.ai_text}" if t.ai_text.present?
      line += " | 音楽家: #{t.user.name}" if t.user
      line
    }.join("\n")

    <<~PROMPT
      ## クライアントの要望
      #{query}

      ## 登録楽曲一覧
      #{track_list}
    PROMPT
  end
  private_class_method :build_prompt

  def self.parse_matches(content, tracks)
    return [] if content.blank?

    parsed = JSON.parse(content)
    return [] unless parsed.is_a?(Array)

    track_map = tracks.index_by(&:uuid)

    parsed.filter_map { |m|
      track = track_map[m['track_uuid']]
      next unless track

      {
        track_uuid: track.uuid,
        title: track.title,
        score: m['score'].to_i,
        reason: m['reason'],
        bpm: track.bpm,
        key: track.key,
        genre: track.genre,
        ai_text: track.ai_text,
        musician: {
          uuid: track.user.uuid,
          name: track.user.name
        }
      }
    }.sort_by { |m| -m[:score] }
  rescue JSON::ParserError
    Rails.logger.warn("AI マッチング結果のJSON解析に失敗: #{content}")
    []
  end
  private_class_method :parse_matches
end
