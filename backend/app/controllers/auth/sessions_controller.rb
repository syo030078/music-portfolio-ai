# app/controllers/auth/sessions_controller.rb
class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env['warden-jwt_auth.token']
    render json: {
      message: 'signed_in',
      token: token ? "Bearer #{token}" : nil,
      user: { id: resource.id, uuid: resource.uuid, email: resource.email, name: resource.name, is_musician: resource.is_musician, is_client: resource.is_client }
    }, status: :ok
  end

  def respond_to_on_destroy
    # AuthorizationヘッダのJWTはミドルウェアがdenylist登録する
    head :no_content
  end
end
