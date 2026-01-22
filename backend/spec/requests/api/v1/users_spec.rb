# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User').reload }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def auth_headers_for(user)
    post '/auth/sign_in', params: {
      user: { email: user.email, password: 'password123' }
    }.to_json, headers: headers

    token = response.headers['Authorization']
    headers.merge('Authorization' => token)
  end

  describe 'GET /api/v1/user' do
    context 'when authenticated' do
      it 'returns user with uuid instead of id' do
        auth_headers = auth_headers_for(user)
        get '/api/v1/user', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key('uuid')
        expect(json).not_to have_key('id')
        expect(json['uuid']).to eq(user.uuid)
      end

      it 'includes required user fields' do
        auth_headers = auth_headers_for(user)
        get '/api/v1/user', headers: auth_headers

        json = JSON.parse(response.body)

        expect(json).to include(
          'uuid' => user.uuid,
          'email' => 'test@example.com',
          'name' => 'Test User'
        )
      end
    end
  end

  describe 'PATCH /api/v1/user' do
    context 'when authenticated' do
      it 'updates user and returns uuid instead of id' do
        auth_headers = auth_headers_for(user)
        patch '/api/v1/user', params: { user: { name: 'Updated Name' } }.to_json, headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key('uuid')
        expect(json).not_to have_key('id')
        expect(json['name']).to eq('Updated Name')
      end
    end
  end
end
