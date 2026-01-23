require 'rails_helper'

RSpec.describe 'Api::V1::Proposals', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', name: 'Client', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', name: 'Musician', is_musician: true).reload }
  let(:other_musician) { User.create!(email: 'musician2@example.com', password: 'password123', name: 'Musician2', is_musician: true).reload }
  let(:job) do
    Job.create!(
      client: client,
      title: 'Need a remix',
      description: 'Test description',
      status: 'published',
      published_at: Time.current
    ).reload
  end

  def auth_headers_for(user)
    post '/auth/sign_in', params: {
      user: { email: user.email, password: 'password123' }
    }.to_json, headers: headers

    token = response.headers['Authorization']
    headers.merge('Authorization' => token)
  end

  describe 'POST /api/v1/jobs/:uuid/proposals' do
    it 'creates a proposal for musician' do
      auth_headers = auth_headers_for(musician)

      post "/api/v1/jobs/#{job.uuid}/proposals", params: {
        proposal: {
          quote_total_jpy: 50_000,
          delivery_days: 7,
          cover_message: 'よろしくお願いします'
        }
      }.to_json, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['proposal']).to have_key('uuid')
      expect(json['proposal']['status']).to eq('submitted')
    end

    it 'rejects duplicate proposals' do
      Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      auth_headers = auth_headers_for(musician)

      post "/api/v1/jobs/#{job.uuid}/proposals", params: {
        proposal: { quote_total_jpy: 60_000, delivery_days: 10 }
      }.to_json, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'forbids client from creating proposal' do
      auth_headers = auth_headers_for(client)

      post "/api/v1/jobs/#{job.uuid}/proposals", params: {
        proposal: { quote_total_jpy: 50_000, delivery_days: 7 }
      }.to_json, headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/jobs/:uuid/proposals' do
    it 'returns proposals for job owner' do
      Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      Proposal.create!(job: job, musician: other_musician, quote_total_jpy: 60_000, delivery_days: 10)
      auth_headers = auth_headers_for(client)

      get "/api/v1/jobs/#{job.uuid}/proposals", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['proposals'].length).to eq(2)
      expect(json['proposals'].first['musician']).to have_key('uuid')
    end

    it 'forbids non-owner' do
      auth_headers = auth_headers_for(musician)

      get "/api/v1/jobs/#{job.uuid}/proposals", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/proposals/:uuid/accept' do
    it 'accepts proposal for job owner' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      proposal.reload
      auth_headers = auth_headers_for(client)

      post "/api/v1/proposals/#{proposal.uuid}/accept", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['proposal']['status']).to eq('accepted')
      expect(json['contract_uuid']).to be_present
      expect(json['conversation_uuid']).to be_present
      expect(proposal.reload).to be_accepted
      expect(job.reload).to be_contracted
    end

    it 'forbids non-owner' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      proposal.reload
      auth_headers = auth_headers_for(musician)

      post "/api/v1/proposals/#{proposal.uuid}/accept", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/proposals/:uuid/reject' do
    it 'rejects proposal for job owner' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      proposal.reload
      auth_headers = auth_headers_for(client)

      post "/api/v1/proposals/#{proposal.uuid}/reject", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['proposal']['status']).to eq('rejected')
      expect(proposal.reload).to be_rejected
    end

    it 'forbids non-owner' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7)
      proposal.reload
      auth_headers = auth_headers_for(musician)

      post "/api/v1/proposals/#{proposal.uuid}/reject", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
