# app/controllers/auth/registrations_controller.rb
class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
    if resource.persisted?
      render json: {
        message: 'Signed up successfully.',
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name
        }
      }, status: :ok
    else
      render json: {
        message: 'User could not be created successfully.',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
