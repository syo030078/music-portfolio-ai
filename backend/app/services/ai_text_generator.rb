# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

class AiTextGenerator
  OPENAI_URL = 'https://api.openai.com/v1/chat/completions'
  MODEL = 'gpt-4o-mini'
  TIMEOUT_SECONDS = 10
  SYSTEM_PROMPT = <<~SYSTEM.freeze
    あなたは音楽の専門家です。楽曲の解析データをもとに、その楽曲の特徴・雰囲気・おすすめの用途を日本語で説明してください。
    説明は、楽曲を探しているクライアント（映像制作者、広告担当者など）と、自分の音楽を客観的に理解したいミュージシャンの両方にとって有用な内容にしてください。
    具体的な数値データに基づいた客観的な分析と、感覚的な雰囲気の描写をバランスよく含めてください。
  SYSTEM

  def self.call(bpm:, key:, genre:, analysis_data: {})
    api_key = ENV['OPENAI_API_KEY']
    unless api_key.present?
      Rails.logger.warn("OPENAI_API_KEY が未設定のため ai_text 生成をスキップします")
      return nil
    end

    prompt = build_prompt(bpm: bpm, key: key, genre: genre, analysis_data: analysis_data)

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
      max_tokens: 300,
      temperature: 0.7
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("OpenAI API エラー: #{response.code} #{response.body}")
      return nil
    end

    body = JSON.parse(response.body)
    body.dig('choices', 0, 'message', 'content')&.strip
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("OpenAI API タイムアウト: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("OpenAI レスポンス解析失敗: #{e.message}")
    nil
  rescue => e
    Rails.logger.error("AiTextGenerator エラー: #{e.class} - #{e.message}")
    nil
  end

  def self.build_prompt(bpm:, key:, genre:, analysis_data: {})
    data = analysis_data || {}

    lines = [
      "以下の楽曲解析データをもとに、この楽曲の特徴・雰囲気・おすすめの用途を3〜4文で説明してください。",
      "",
      "- BPM: #{bpm}",
      "- キー: #{key}",
      "- ジャンル: #{genre}"
    ]

    lines << "- エネルギーレベル: #{data['energy_level']}" if data['energy_level'].present?
    lines << "- テンポ安定性: #{data['tempo_stability']}" if data['tempo_stability'].present?
    lines << "- 楽曲の長さ: #{data['duration_sec']&.round}秒" if data['duration_sec'].present?
    lines << "- 音色の明るさ: #{data['spectral_brightness']}" if data['spectral_brightness'].present?

    if data['sections'].is_a?(Array) && data['sections'].any?
      sections_text = data['sections'].map { |s|
        "#{s['label']}(#{s['start_sec'].to_f.round}s〜#{s['end_sec'].to_f.round}s)"
      }.join(", ")
      lines << "- 楽曲構成: #{sections_text}"
    end

    lines.join("\n")
  end
  private_class_method :build_prompt
end
