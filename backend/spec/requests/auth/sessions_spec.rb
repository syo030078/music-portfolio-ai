require 'rails_helper'

RSpec.describe 'User Sessions', type: :request do
  describe 'POST /auth/sign_in' do
    let!(:user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User') }
    let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

    context '有効な認証情報の場合' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
      end

      it '200ステータスを返す' do
        post '/auth/sign_in', params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'JWTトークンをAuthorizationヘッダーに含む' do
        post '/auth/sign_in', params: valid_params.to_json, headers: headers
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'ユーザー情報を返す' do
        post '/auth/sign_in', params: valid_params.to_json, headers: headers
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('test@example.com')
        expect(json['user']['name']).to eq('Test User')
      end
    end

    context '無効な認証情報の場合' do
      it 'パスワードが間違っている場合、401を返す' do
        invalid_params = {
          user: {
            email: 'test@example.com',
            password: 'wrongpassword'
          }
        }
        post '/auth/sign_in', params: invalid_params.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end

      it '存在しないメールアドレスの場合、401を返す' do
        invalid_params = {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        post '/auth/sign_in', params: invalid_params.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /auth/sign_out' do
    let!(:user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User') }
    let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

    context '有効なJWTトークンがある場合' do
      it '204ステータスを返す' do
        # ログインしてトークン取得
        post '/auth/sign_in', params: {
          user: { email: 'test@example.com', password: 'password123' }
        }.to_json, headers: headers

        token = response.headers['Authorization']

        # ログアウト
        delete '/auth/sign_out', headers: headers.merge('Authorization' => token)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
