# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Tracks', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', name: 'Test User').reload }

  let!(:track) do
    Track.create!(
      user: user,
      title: 'Test Track',
      description: 'A test track description',
      yt_url: 'https://youtube.com/watch?v=test123',
      bpm: 120.5,
      key: 'C major',
      genre: 'Rock',
      ai_text: 'AI generated text'
    ).reload
  end

  describe 'GET /api/v1/tracks' do
    it 'returns tracks with uuid instead of id' do
      get '/api/v1/tracks'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      track_data = json['tracks'].first

      expect(track_data).to have_key('uuid')
      expect(track_data).not_to have_key('id')
      expect(track_data['uuid']).to eq(track.uuid)
    end

    it 'returns user with uuid instead of id' do
      get '/api/v1/tracks'

      json = JSON.parse(response.body)
      user_data = json['tracks'].first['user']

      expect(user_data).to have_key('uuid')
      expect(user_data).not_to have_key('id')
      expect(user_data['uuid']).to eq(user.uuid)
    end

    it 'includes all required track fields' do
      get '/api/v1/tracks'

      json = JSON.parse(response.body)
      track_data = json['tracks'].first

      expect(track_data).to include(
        'uuid' => track.uuid,
        'title' => 'Test Track',
        'description' => 'A test track description',
        'yt_url' => 'https://youtube.com/watch?v=test123',
        'bpm' => 120.5,
        'key' => 'C major',
        'genre' => 'Rock',
        'ai_text' => 'AI generated text'
      )
      expect(track_data['created_at']).to be_present
    end

    it 'includes pagination' do
      get '/api/v1/tracks'

      json = JSON.parse(response.body)
      expect(json['pagination']).to include(
        'current_page' => 1,
        'per_page' => 10
      )
    end
  end

  describe 'GET /api/v1/tracks/:uuid' do
    context 'with valid uuid' do
      it 'returns track with uuid instead of id' do
        get "/api/v1/tracks/#{track.uuid}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        track_data = json['track']

        expect(track_data).to have_key('uuid')
        expect(track_data).not_to have_key('id')
        expect(track_data['uuid']).to eq(track.uuid)
      end

      it 'returns user with uuid instead of id' do
        get "/api/v1/tracks/#{track.uuid}"

        json = JSON.parse(response.body)
        user_data = json['track']['user']

        expect(user_data).to have_key('uuid')
        expect(user_data).not_to have_key('id')
        expect(user_data['uuid']).to eq(user.uuid)
      end

      it 'includes all required track fields' do
        get "/api/v1/tracks/#{track.uuid}"

        json = JSON.parse(response.body)
        track_data = json['track']

        expect(track_data).to include(
          'uuid' => track.uuid,
          'title' => 'Test Track',
          'description' => 'A test track description',
          'yt_url' => 'https://youtube.com/watch?v=test123',
          'bpm' => 120.5,
          'key' => 'C major',
          'genre' => 'Rock',
          'ai_text' => 'AI generated text'
        )
        expect(track_data['created_at']).to be_present
        expect(track_data['updated_at']).to be_present
      end
    end

    context 'with invalid uuid' do
      it 'returns 404 for non-existent uuid' do
        get '/api/v1/tracks/non-existent-uuid'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end
  end

  describe 'POST /api/v1/tracks' do
    let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

    def auth_headers_for(user)
      post '/auth/sign_in', params: {
        user: { email: user.email, password: 'password123' }
      }.to_json, headers: headers

      headers.merge('Authorization' => response.headers['Authorization'])
    end

    it 'registers a YouTube track' do
      auth_headers = auth_headers_for(user)

      expect {
        post '/api/v1/tracks',
             params: { yt_url: 'https://www.youtube.com/watch?v=abc', title: 'My Video' }.to_json,
             headers: auth_headers
      }.to change(Track, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']).to include('yt_url' => 'https://www.youtube.com/watch?v=abc', 'title' => 'My Video')
      expect(json['data']['uuid']).to be_present
    end

    it 'returns top-level error for invalid YouTube URL' do
      auth_headers = auth_headers_for(user)

      post '/api/v1/tracks',
           params: { yt_url: 'https://example.com/not-youtube' }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns top-level error when neither audio_file nor yt_url is given' do
      auth_headers = auth_headers_for(user)

      post '/api/v1/tracks', params: {}.to_json, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('音声ファイルまたはYouTube URLを指定してください')
    end

    it 'returns 401 without authentication' do
      post '/api/v1/tracks', params: { yt_url: 'https://www.youtube.com/watch?v=abc' }.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
