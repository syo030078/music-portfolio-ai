# app/controllers/auth/sessions_controller.rb
class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env['warden-jwt_auth.token']
    render json: {
      message: 'signed_in',
      token: token ? "Bearer #{token}" : nil,
      user: { id: resource.id, email: resource.email, name: resource.name }
    }, status: :ok
  end

  def respond_to_on_destroy
    # AuthorizationヘッダのJWTはミドルウェアがdenylist登録する
    head :no_content
  end
end
