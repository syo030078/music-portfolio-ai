# frozen_string_literal: true

class Api::V1::MatchingController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    query = params[:query]&.strip

    if query.blank?
      render json: { error: "検索クエリを入力してください" }, status: :bad_request
      return
    end

    result = AiMatchingService.call(query: query)

    if result[:error]
      render json: { error: result[:error] }, status: :service_unavailable
      return
    end

    render json: { matches: result[:matches] }
  end
end
