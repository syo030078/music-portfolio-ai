# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user_from_token!

  def show
    render json: { id: current_user.id, email: current_user.email, name: current_user.name }
  end
end
