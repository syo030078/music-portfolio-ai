require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let!(:user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User') }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  describe 'GET /api/v1/user' do
    context '未認証の場合' do
      it '401を返す' do
        get '/api/v1/user', headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '認証済みの場合' do
      it 'ユーザー情報を返す' do
        post '/auth/sign_in', params: {
          user: { email: 'test@example.com', password: 'password123' }
        }.to_json, headers: headers

        token = response.headers['Authorization']

        get '/api/v1/user', headers: headers.merge('Authorization' => token)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['email']).to eq('test@example.com')
        expect(json['name']).to eq('Test User')
      end
    end
  end
end
