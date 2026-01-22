# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Messages', type: :request do
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

  describe 'POST /api/v1/conversations/:conversation_uuid/messages' do
    it 'creates message and returns uuid instead of id' do
      post "/api/v1/conversations/#{conversation.id}/messages", params: {
        message: { content: 'New test message' }
      }

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
