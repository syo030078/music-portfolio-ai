class Api::V1::TracksController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render json: { message: "load_wav", status: "ok" }
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
    else
      # テスト用（ファイル無しの場合はフォールバック）
      result = AnalyzerRunner.call("test.wav")
      render json: { message: "load_wav created", data: result }
    end
  end
end
