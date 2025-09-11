class Api::V1::TracksController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render json: { message: "load_wav", status: "ok" }
  end

  def create
    audio_file = params[:audio_file]
    file_path = audio_file ? audio_file.original_filename : "test.wav"
    
    result = AnalyzerRunner.call(file_path)
    render json: { message: "load_wav created", result: result }
  end
end
