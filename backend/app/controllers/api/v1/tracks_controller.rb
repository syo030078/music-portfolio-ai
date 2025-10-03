class Api::V1::TracksController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render json: { message: "load_wav", status: "ok" }
  end

  def create
    audio_file = params[:audio_file]

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
      render json: { data: { error: "音声ファイルが指定されていません" } }, status: :bad_request
    end
  end
end
