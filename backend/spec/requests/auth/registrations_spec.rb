require 'rails_helper'

RSpec.describe 'User Registration', type: :request do
  describe 'POST /auth' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User'
        }
      }
    end

    let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

    context '有効なパラメータの場合' do
      it 'ユーザーが作成される' do
        expect {
          post '/auth', params: valid_params.to_json, headers: headers
        }.to change(User, :count).by(1)
      end

      it '200ステータスを返す' do
        post '/auth', params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'JWTトークンをAuthorizationヘッダーに含む' do
        post '/auth', params: valid_params.to_json, headers: headers
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'ユーザー情報を返す' do
        post '/auth', params: valid_params.to_json, headers: headers
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('test@example.com')
        expect(json['user']['name']).to eq('Test User')
      end
    end

    context '無効なパラメータの場合' do
      it 'メールアドレスが空の場合、エラーを返す' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ''

        post '/auth', params: invalid_params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'パスワードが短すぎる場合、エラーを返す' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password] = '123'

        post '/auth', params: invalid_params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '重複するメールアドレスの場合、エラーを返す' do
        User.create!(email: 'test@example.com', password: 'password123', name: 'Existing User')

        post '/auth', params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
