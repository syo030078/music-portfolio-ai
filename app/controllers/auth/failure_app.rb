class Auth::FailureApp < Devise::FailureApp
  def respond
    if request.content_type == 'application/json'
      json_error_response
    else
      super
    end
  end

  private

  def json_error_response
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { error: 'Unauthorized' }.to_json
  end
end