# app/controllers/api/v1/tracks_controller.rb
class Api::V1::TracksController < ApplicationController
  before_action :authenticate_user!

  def create
    track = current_user.tracks.create!(track_params)

    begin
      res = AnalyzerRunner.call(track.yt_url)
      track.update!(bpm: res["bpm"], key: res["key"], genre: res["genre"], ai_text: res["ai_text"])
    rescue => e
      Rails.logger.error("[Analyzer] #{e.class}: #{e.message}")
      # MVPなので失敗しても作成は成功にする
    end

    render json: { id: track.id }, status: :created
  end

  def index
    render json: current_user.tracks.order(id: :desc)
  end

  def show
    track = current_user.tracks.find(params[:id])
    render json: track
  end

  private
  def track_params
    params.require(:track).permit(:title, :description, :yt_url)
  end
end
