class DeviseFailureApp < Devise::FailureApp
  def respond
    if request.format.json?
      json_error
    else
      # API-only だが、万一HTMLなどで来た場合も 401 を返す
      http_auth
    end
  end

  private

  def json_error
    self.status       = :unauthorized
    self.content_type = 'application/json'
    self.response_body = { error: i18n_message }.to_json
  end

  # APIではセッションに保存しない（DisabledSessionError回避）
  def store_location!
    # no-op
  end
end
