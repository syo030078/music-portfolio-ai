# app/controllers/auth/sessions_controller.rb
class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: {
      message: 'signed_in',
      user: { id: resource.id, email: resource.email, name: resource.name }
    }, status: :ok
  end

  def respond_to_on_destroy
    # AuthorizationヘッダのJWTはミドルウェアがdenylist登録する
    head :no_content
  end
end
