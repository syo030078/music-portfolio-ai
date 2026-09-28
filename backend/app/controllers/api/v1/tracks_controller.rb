class Api::V1::TracksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def generate_ai_text
    track = current_user.tracks.find_by(uuid: params[:id])

    if track.nil?
      render_error("楽曲が見つかりません", :not_found)
      return
    end

    unless track.bpm || track.key || track.genre
      render_error("解析データがないため AI 説明文を生成できません", :unprocessable_entity)
      return
    end

    ai_text = AiTextGenerator.call(
      bpm: track.bpm,
      key: track.key,
      genre: track.genre
    )

    if ai_text.nil?
      render_error("AI 説明文の生成に失敗しました。しばらく経ってから再度お試しください", :service_unavailable)
      return
    end

    track.update_column(:ai_text, ai_text)

    render json: {
      track: {
        uuid: track.uuid,
        ai_text: track.ai_text
      }
    }
  end

  def index
    # ページネーション設定
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10
    per_page = [per_page, 50].min # 最大50件

    tracks = Track.includes(:user)
                  .by_user_uuid(params[:user_uuid])
                  .by_genre(params[:genre])
                  .by_key(params[:key])
                  .bpm_min(params[:bpm_min])
                  .bpm_max(params[:bpm_max])
                  .order(created_at: :desc)

    total_count = tracks.count
    tracks = tracks.offset((page - 1) * per_page).limit(per_page)

    render json: {
      tracks: tracks.map { |track| track_payload(track) },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count,
        per_page: per_page
      }
    }
  end

  def show
    track = Track.includes(:user).find_by(uuid: params[:id])

    if track.nil?
      render_error("楽曲が見つかりません", :not_found)
      return
    end

    render json: { track: track_payload(track, detail: true) }
  end

  def create
    audio_file = params[:audio_file]
    yt_url = params[:yt_url]
    title = params[:title]

    # YouTube URL登録の処理
    if yt_url.present?
      track = Track.new(
        user_id: current_user.id,
        yt_url: yt_url,
        title: title || "Untitled"
      )

      if track.save
        track.reload
        render json: {
          message: "YouTube動画を登録しました",
          data: {
            uuid: track.uuid,
            yt_url: track.yt_url,
            title: track.title
          }
        }, status: :created
      else
        render_error(track.errors.full_messages.join(", "), :unprocessable_entity)
      end
      return
    end

    # 音声ファイル解析の処理
    if audio_file
      result = TrackAudioAnalysisService.call(user: current_user, audio_file: audio_file, title: title)

      if result.success?
        render json: { message: result.message, data: result.data }, status: :created
      else
        render_error(result.error, result.status)
      end
    else
      render_error("音声ファイルまたはYouTube URLを指定してください", :bad_request)
    end
  end

  private

  # detail: true は詳細画面用（updated_at と投稿者の email を含む）
  def track_payload(track, detail: false)
    user = { uuid: track.user.uuid, name: track.user.name, bio: track.user.bio }
    user = user.merge(email: track.user.email) if detail

    payload = {
      uuid: track.uuid,
      title: track.title,
      description: track.description,
      yt_url: track.yt_url,
      bpm: track.bpm,
      key: track.key,
      genre: track.genre,
      ai_text: track.ai_text,
      created_at: track.created_at,
      user: user
    }
    detail ? payload.merge(updated_at: track.updated_at) : payload
  end
end
