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
end
