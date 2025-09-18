module Api
  module V1
    class TracksController < ApplicationController
      skip_before_action :authenticate_user!

      def index
        tracks = Track.all.order(created_at: :desc)
        render json: { data: tracks.map { |t| { id: t.id, title: t.title, yt_url: t.yt_url } } }
      end

      def create
        audio_file = params[:audio_file]

        if audio_file
          # 一時ファイル保存（タイムスタンプ付きで重複回避）
          timestamp = Time.current.strftime("%Y%m%d_%H%M%S_%L")
          filename = "#{timestamp}_#{audio_file.original_filename}"
          temp_path = Rails.root.join('tmp', 'uploads', filename)
          FileUtils.mkdir_p(File.dirname(temp_path))
          File.write(temp_path, audio_file.read, mode: 'wb')

          begin
            # Python解析実行
            result = AnalyzerRunner.call(temp_path.to_s)
            render json: { message: "load_wav created", data: result }
          ensure
            # 一時ファイル削除
            File.delete(temp_path) if File.exist?(temp_path)
          end
        elsif params[:yt_url] && params[:title]
          # YouTube登録
          track = Track.create!(
            title: params[:title],
            yt_url: params[:yt_url],
            user_id: 1
          )
          render json: { message: "YouTube登録完了", data: { id: track.id, title: track.title, yt_url: track.yt_url } }
        else
          # テスト用（ファイル無しの場合はフォールバック）
          result = AnalyzerRunner.call("test.wav")
          render json: { message: "load_wav created", data: result }
        end
      end
    end
  end
end
