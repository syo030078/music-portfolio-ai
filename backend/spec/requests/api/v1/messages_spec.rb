# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Messages', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:client) { User.create!(email: 'client1@example.com', password: 'password123', name: 'Client User', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', name: 'Musician User', is_musician: true).reload }

  let!(:job) do
    Job.create!(
      client: client,
      title: 'Test Job',
      description: 'Test description',
      status: 'published',
      published_at: Time.current
    ).reload
  end

  let!(:conversation) do
    conv = Conversation.create!(job: job)
    conv.conversation_participants.create!(user: client)
    conv.conversation_participants.create!(user: musician)
    conv
  end

  def auth_headers_for(user)
    post '/auth/sign_in', params: {
      user: { email: user.email, password: 'password123' }
    }.to_json, headers: headers

    token = response.headers['Authorization']
    headers.merge('Authorization' => token)
  end

  describe 'GET /api/v1/conversations/:conversation_id/messages' do
    let!(:old_message) do
      conversation.messages.create!(sender: client, content: '古いメッセージ')
    end
    let!(:new_message) do
      conversation.messages.create!(sender: musician, content: '新しいメッセージ')
    end

    it 'returns messages for conversation' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages", headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['messages'].length).to eq(2)
      expect(json['messages'].first['uuid']).to eq(old_message.uuid)
      expect(json['messages'].last['uuid']).to eq(new_message.uuid)
      expect(json).to have_key('meta')
    end

    it 'filters messages by since parameter' do
      auth = auth_headers_for(client)
      since = old_message.created_at.iso8601(6)

      get "/api/v1/conversations/#{conversation.id}/messages",
          params: { since: since },
          headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['messages'].length).to eq(1)
      expect(json['messages'].first['uuid']).to eq(new_message.uuid)
    end

    it 'respects limit parameter' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages",
          params: { limit: 1 },
          headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['messages'].length).to eq(1)
    end

    it 'returns messages using uuid fields' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages", headers: auth

      json = JSON.parse(response.body)
      msg = json['messages'].first
      expect(msg).to have_key('uuid')
      expect(msg).not_to have_key('id')
      expect(msg).to have_key('sender_uuid')
      expect(msg).not_to have_key('sender_id')
      expect(msg).to have_key('sender_name')
      expect(msg).to have_key('content')
      expect(msg).to have_key('created_at')
    end

    it 'returns 403 for non-participant' do
      outsider = User.create!(email: 'outsider@example.com', password: 'password123', name: 'Outsider', is_client: true)
      auth = auth_headers_for(outsider)
      get "/api/v1/conversations/#{conversation.id}/messages", headers: auth

      expect(response).to have_http_status(:forbidden)
    end

    it 'marks conversation as read when new messages exist' do
      auth = auth_headers_for(client)
      participant = conversation.conversation_participants.find_by(user_id: client.id)
      participant.update!(last_read_at: 1.day.ago)

      get "/api/v1/conversations/#{conversation.id}/messages", headers: auth

      participant.reload
      expect(participant.last_read_at).to be_within(2.seconds).of(Time.current)
    end

    it 'does not update last_read_at when already up to date' do
      auth = auth_headers_for(client)
      participant = conversation.conversation_participants.find_by(user_id: client.id)
      future_time = 1.hour.from_now
      participant.update!(last_read_at: future_time)

      get "/api/v1/conversations/#{conversation.id}/messages", headers: auth

      participant.reload
      expect(participant.last_read_at).to be_within(2.seconds).of(future_time)
    end

    it 'filters messages by before parameter (cursor pagination)' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages",
          params: { before: new_message.uuid },
          headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['messages'].length).to eq(1)
      expect(json['messages'].first['uuid']).to eq(old_message.uuid)
    end

    it 'returns has_more correctly with limit+1 pattern' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages",
          params: { limit: 1 },
          headers: auth

      json = JSON.parse(response.body)
      expect(json['meta']['has_more']).to be true
      expect(json['messages'].length).to eq(1)
    end

    it 'returns 400 for malformed since parameter' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}/messages",
          params: { since: 'not-a-date' },
          headers: auth

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 401 for unauthenticated request' do
      get "/api/v1/conversations/#{conversation.id}/messages", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/conversations/:conversation_uuid/messages' do
    it 'creates message and returns uuid instead of id' do
      auth = auth_headers_for(client)
      post "/api/v1/conversations/#{conversation.id}/messages", params: {
        message: { content: 'New test message' }
      }.to_json, headers: auth

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      msg_data = json['message']

      expect(msg_data).to have_key('uuid')
      expect(msg_data).not_to have_key('id')
      expect(msg_data).to have_key('sender_uuid')
      expect(msg_data).not_to have_key('sender_id')
      expect(msg_data['content']).to eq('New test message')
    end
  end
end
