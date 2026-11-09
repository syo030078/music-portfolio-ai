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
    let(:outsider) { User.create!(email: 'outsider@example.com', password: 'password123', name: 'Outsider', is_musician: true).reload }
    let!(:new_job) do
      Job.create!(
        client: client,
        title: 'New Job',
        description: 'New description',
        status: 'published',
        published_at: Time.current
      ).reload
    end

    it 'job_uuid で会話を作り、uuid を返す' do
      auth = auth_headers_for(musician)
      post '/api/v1/conversations', params: {
        conversation: { job_uuid: new_job.uuid }
      }.to_json, headers: auth

      expect(response).to have_http_status(:created)
      conv_data = JSON.parse(response.body)['conversation']

      expect(conv_data).to have_key('uuid')
      expect(conv_data).not_to have_key('id')
      expect(conv_data['job_uuid']).to eq(new_job.uuid)
      expect(conv_data).not_to have_key('job_id')

      created = Conversation.find(conv_data['uuid'])
      expect(created.participants).to contain_exactly(client, musician)
    end

    it 'participant_uuids で第三者を参加者に追加できない' do
      auth = auth_headers_for(musician)
      post '/api/v1/conversations', params: {
        conversation: { job_uuid: new_job.uuid },
        participant_uuids: [outsider.uuid]
      }.to_json, headers: auth

      expect(response).to have_http_status(:created)
      created = Conversation.find(JSON.parse(response.body)['conversation']['uuid'])
      expect(created.participants).not_to include(outsider)
    end

    it '内部IDの job_id / participant_ids は受け付けない' do
      auth = auth_headers_for(musician)
      expect do
        post '/api/v1/conversations', params: {
          conversation: { job_id: new_job.id },
          participant_ids: [outsider.id]
        }.to_json, headers: auth
      end.not_to change(Conversation, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it '当事者でない契約の会話は作れない' do
      proposal = Proposal.create!(job: new_job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7, cover_message: 'よろしく')
      contract = Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50_000, status: 'active').reload

      auth = auth_headers_for(outsider)
      post '/api/v1/conversations', params: {
        conversation: { contract_uuid: contract.uuid }
      }.to_json, headers: auth

      expect(response).to have_http_status(:forbidden)
    end

    it '存在しない案件は 404' do
      auth = auth_headers_for(musician)
      post '/api/v1/conversations', params: {
        conversation: { job_uuid: SecureRandom.uuid }
      }.to_json, headers: auth

      expect(response).to have_http_status(:not_found)
    end
  end
end
