# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Conversations', type: :request do
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

  let!(:message) do
    Message.create!(
      conversation: conversation,
      sender: client,
      content: 'Hello, this is a test message'
    ).reload
  end

  def auth_headers_for(user)
    post '/auth/sign_in', params: {
      user: { email: user.email, password: 'password123' }
    }.to_json, headers: headers

    token = response.headers['Authorization']
    headers.merge('Authorization' => token)
  end

  describe 'GET /api/v1/conversations' do
    it 'returns conversations with uuid field' do
      auth = auth_headers_for(client)
      get '/api/v1/conversations', headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      conv_data = json['conversations'].first

      expect(conv_data).to have_key('uuid')
      expect(conv_data).not_to have_key('id')
      expect(conv_data['uuid']).to eq(conversation.id)
    end

    it 'returns job_uuid instead of job_id' do
      auth = auth_headers_for(client)
      get '/api/v1/conversations', headers: auth

      json = JSON.parse(response.body)
      conv_data = json['conversations'].first

      expect(conv_data).to have_key('job_uuid')
      expect(conv_data).not_to have_key('job_id')
      expect(conv_data['job_uuid']).to eq(job.uuid)
    end

    it 'returns participants with uuid instead of id' do
      auth = auth_headers_for(client)
      get '/api/v1/conversations', headers: auth

      json = JSON.parse(response.body)
      participants = json['conversations'].first['participants']

      participants.each do |p|
        expect(p).to have_key('uuid')
        expect(p).not_to have_key('id')
      end
    end

    it 'returns last_message with uuid instead of id' do
      auth = auth_headers_for(client)
      get '/api/v1/conversations', headers: auth

      json = JSON.parse(response.body)
      last_msg = json['conversations'].first['last_message']

      expect(last_msg).to have_key('uuid')
      expect(last_msg).not_to have_key('id')
      expect(last_msg).to have_key('sender_uuid')
      expect(last_msg).not_to have_key('sender_id')
    end
  end

  describe 'GET /api/v1/conversations/:uuid' do
    it 'returns conversation with uuid field' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}", headers: auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      conv_data = json['conversation']

      expect(conv_data).to have_key('uuid')
      expect(conv_data).not_to have_key('id')
      expect(conv_data['uuid']).to eq(conversation.id)
    end

    it 'returns job_uuid instead of job_id' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}", headers: auth

      json = JSON.parse(response.body)
      conv_data = json['conversation']

      expect(conv_data).to have_key('job_uuid')
      expect(conv_data).not_to have_key('job_id')
      expect(conv_data['job_uuid']).to eq(job.uuid)
    end

    it 'returns participants with uuid instead of id' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}", headers: auth

      json = JSON.parse(response.body)
      participants = json['conversation']['participants']

      participants.each do |p|
        expect(p).to have_key('uuid')
        expect(p).not_to have_key('id')
      end
    end

    it 'returns messages with uuid instead of id' do
      auth = auth_headers_for(client)
      get "/api/v1/conversations/#{conversation.id}", headers: auth

      json = JSON.parse(response.body)
      messages = json['conversation']['messages']

      messages.each do |msg|
        expect(msg).to have_key('uuid')
        expect(msg).not_to have_key('id')
        expect(msg).to have_key('sender_uuid')
        expect(msg).not_to have_key('sender_id')
      end
    end
  end

  describe 'POST /api/v1/conversations' do
    it 'creates conversation and returns uuid' do
      new_job = Job.create!(
        client: client,
        title: 'New Job',
        description: 'New description',
        status: 'published',
        published_at: Time.current
      ).reload

      auth = auth_headers_for(client)
      post '/api/v1/conversations', params: {
        conversation: { job_id: new_job.id },
        participant_ids: [musician.id]
      }.to_json, headers: auth

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      conv_data = json['conversation']

      expect(conv_data).to have_key('uuid')
      expect(conv_data).not_to have_key('id')
      expect(conv_data).to have_key('job_uuid')
      expect(conv_data).not_to have_key('job_id')
    end
  end
end
