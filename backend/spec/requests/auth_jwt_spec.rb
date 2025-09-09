require 'rails_helper'

RSpec.describe 'JWT Authentication', type: :request do
  let!(:user) { User.create!(email: 'test@example.com', password: 'password', name: 'Test User') }

  def auth_header(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  it 'issues JWT on sign_in and allows /me, then revokes on sign_out' do
    # sign_in
    post '/auth/sign_in', params: { user: { email: user.email, password: 'password' } }, as: :json
    expect(response).to have_http_status(:ok)
    token = response.headers['Authorization']&.split(' ')&.last
    expect(token).to be_present

    # /me success
    get '/me', headers: auth_header(token)
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json['email']).to eq user.email

    # sign_out
    delete '/auth/sign_out', headers: auth_header(token)
    expect(response).to have_http_status(:no_content)
    expect(JwtDenylist.count).to eq 1

    # revoked token
    get '/me', headers: auth_header(token)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects wrong password' do
    post '/auth/sign_in', params: { user: { email: user.email, password: 'wrong' } }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects request without token' do
    get '/me'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects invalid token' do
    get '/me', headers: auth_header('invalid.token.here')
    expect(response).to have_http_status(:unauthorized)
  end
end
