class MeController < ApplicationController
  def show
    render json: current_user.as_json(only: %i[id email name])
  end
end