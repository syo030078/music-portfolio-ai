class Api::V1::ProfilesController < ApplicationController
  def show
    render json: {
      id: current_user.id,
      email: current_user.email,
      name: current_user.name
    }
  end

  def update
    if current_user.update(profile_params)
      render json: current_user
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:name)
  end
end