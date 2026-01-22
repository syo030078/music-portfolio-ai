class Api::V1::TracksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # ページネーション設定
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10
    per_page = [per_page, 50].min # 最大50件

    # 基本クエリ（ユーザー情報を含む）
    tracks = Track.includes(:user)

    # フィルタリング: ジャンル
    tracks = tracks.where(genre: params[:genre]) if params[:genre].present?

    # フィルタリング: BPM範囲
    if params[:bpm_min].present?
      tracks = tracks.where('bpm >= ?', params[:bpm_min].to_f)
    end
    if params[:bpm_max].present?
      tracks = tracks.where('bpm <= ?', params[:bpm_max].to_f)
    end

    # フィルタリング: キー
    tracks = tracks.where(key: params[:key]) if params[:key].present?

    # ソート（新しい順）
    tracks = tracks.order(created_at: :desc)

    # ページネーション適用
    total_count = tracks.count
    total_pages = (total_count.to_f / per_page).ceil
    tracks = tracks.offset((page - 1) * per_page).limit(per_page)

    # レスポンス生成
    render json: {
      tracks: tracks.map do |track|
        {
          uuid: track.uuid,
          title: track.title,
          description: track.description,
          yt_url: track.yt_url,
          bpm: track.bpm,
          key: track.key,
          genre: track.genre,
          ai_text: track.ai_text,
          created_at: track.created_at,
          user: {
            uuid: track.user.uuid,
            name: track.user.name,
            bio: track.user.bio
          }
        }
      end,
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page
      }
    }
  end

  def show
    track = Track.includes(:user).find_by(uuid: params[:id])

    if track.nil?
      render json: { error: "楽曲が見つかりません" }, status: :not_found
      return
    end

    render json: {
      track: {
        uuid: track.uuid,
        title: track.title,
        description: track.description,
        yt_url: track.yt_url,
        bpm: track.bpm,
        key: track.key,
        genre: track.genre,
        ai_text: track.ai_text,
        created_at: track.created_at,
        updated_at: track.updated_at,
        user: {
          uuid: track.user.uuid,
          name: track.user.name,
          bio: track.user.bio,
          email: track.user.email
        }
      }
    }
  end

  def create
    audio_file = params[:audio_file]
    yt_url = params[:yt_url]
    title = params[:title]

    # YouTube URL登録の処理
    if yt_url.present?
      # 仮ユーザーIDを使用（Phase 1: MVP実装）
      user = User.first

      if user.nil?
        render json: { data: { error: "ユーザーが存在しません" } }, status: :internal_server_error
        return
      end

      track = Track.new(
        user_id: user.id,
        yt_url: yt_url,
        title: title || "Untitled"
      )

      if track.save
        render json: {
          message: "YouTube動画を登録しました",
          data: {
            id: track.id,
            yt_url: track.yt_url,
            title: track.title
          }
        }, status: :created
      else
        render json: {
          data: { error: track.errors.full_messages.join(", ") }
        }, status: :unprocessable_entity
      end
      return
    end

    # 音声ファイル解析の処理（既存機能）
    if audio_file
      # 一時ファイル保存
      temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
      FileUtils.mkdir_p(File.dirname(temp_path))
      File.write(temp_path, audio_file.read, mode: 'wb')

      begin
        # Python解析実行
        result = AnalyzerRunner.call(temp_path.to_s)

        # エラーがある場合は適切なステータスコードで返す
        if result[:error]
          render json: { data: result }, status: :unprocessable_entity
        else
          render json: { message: "load_wav created", data: result }
        end
      rescue => e
        Rails.logger.error("解析処理エラー: #{e.message}")
        render json: { data: { error: "解析エラーが発生しました" } }, status: :internal_server_error
      ensure
        # 一時ファイル削除
        File.delete(temp_path) if File.exist?(temp_path)
      end
    else
      render json: { data: { error: "音声ファイルまたはYouTube URLを指定してください" } }, status: :bad_request
    end
  end
end
