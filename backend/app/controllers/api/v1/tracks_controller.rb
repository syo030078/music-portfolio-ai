require 'timeout'
# app/controllers/api/v1/tracks_controller.rb
class Api::V1::TracksController < ApplicationController
  # before_action :authenticate_user!

  def create
    track = current_user.tracks.create!(track_params)

    begin
      Timeout.timeout(45.seconds) do
        res = AnalyzerRunner.call(track.yt_url)
        track.update!(bpm: res["bpm"], key: res["key"], genre: res["genre"], ai_text: res["ai_text"])
      end
    rescue Timeout::Error => e
      Rails.logger.warn("[AnalyzerTimeout] #{e.message} url=#{track.yt_url}")
    rescue StandardError => e
      Rails.logger.error("[AnalyzerError] #{e.class}: #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}")
    end

    render json: track, status: :created
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
