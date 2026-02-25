# app/controllers/auth/registrations_controller.rb
class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :name, :is_musician, :is_client)
  end

  def sign_up(resource_name, resource)
    sign_in(resource_name, resource, store: false)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      resource.reload
      token = jwt_token_for(resource)
      response.set_header('Authorization', "Bearer #{token}") if token

      render json: {
        message: 'Signed up successfully.',
        token: token ? "Bearer #{token}" : nil,
        user: {
          id: resource.id,
          uuid: resource.uuid,
          email: resource.email,
          name: resource.name,
          is_musician: resource.is_musician,
          is_client: resource.is_client
        }
      }, status: :ok
    else
      render json: {
        message: 'User could not be created successfully.',
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def jwt_token_for(resource)
    Warden::JWTAuth::UserEncoder.new.call(resource, :user, nil).first
  rescue StandardError
    nil
  end
end
