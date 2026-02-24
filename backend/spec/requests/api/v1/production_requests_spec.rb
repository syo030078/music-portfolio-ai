require 'rails_helper'

RSpec.describe 'Api::V1::ProductionRequests', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', name: 'Client', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', name: 'Musician', is_musician: true).reload }

  def auth_headers_for(user)
    post '/auth/sign_in', params: {
      user: { email: user.email, password: 'password123' }
    }.to_json, headers: headers

    token = response.headers['Authorization']
    headers.merge('Authorization' => token)
  end

  def create_production_request(client:, musician:)
    ProductionRequest.create!(
      client: client,
      musician: musician,
      title: 'BGM for short film',
      description: 'Need atmospheric ambient music',
      budget_jpy: 80_000,
      delivery_days: 14
    ).reload
  end

  describe 'POST /api/v1/production_requests' do
    let(:valid_params) do
      {
        production_request: {
          musician_uuid: musician.uuid,
          title: 'BGM for short film',
          description: 'Need atmospheric ambient music',
          budget_jpy: 80_000,
          delivery_days: 14
        }
      }.to_json
    end

    it 'creates a production request as client' do
      post '/api/v1/production_requests', params: valid_params, headers: auth_headers_for(client)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['production_request']['uuid']).to be_present
      expect(json['production_request']['status']).to eq('pending')
      expect(json['production_request']['musician']['uuid']).to eq(musician.uuid)
      expect(json['production_request']['client']['uuid']).to eq(client.uuid)
    end

    it 'forbids musicians from creating requests' do
      post '/api/v1/production_requests', params: valid_params, headers: auth_headers_for(musician)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not_found for unknown musician_uuid' do
      params = {
        production_request: {
          musician_uuid: 'nonexistent-uuid',
          title: 'Test',
          description: 'Test description',
          budget_jpy: 1000,
          delivery_days: 1
        }
      }.to_json
      post '/api/v1/production_requests', params: params, headers: auth_headers_for(client)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns unprocessable_entity for non-musician user' do
      other_client = User.create!(email: 'other_client@example.com', password: 'password123', name: 'OtherClient', is_client: true).reload
      params = {
        production_request: {
          musician_uuid: other_client.uuid,
          title: 'Test',
          description: 'Test description',
          budget_jpy: 1000,
          delivery_days: 1
        }
      }.to_json
      post '/api/v1/production_requests', params: params, headers: auth_headers_for(client)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable_entity for invalid params' do
      params = {
        production_request: {
          musician_uuid: musician.uuid,
          title: '',
          description: '',
          budget_jpy: -1,
          delivery_days: 0
        }
      }.to_json
      post '/api/v1/production_requests', params: params, headers: auth_headers_for(client)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/production_requests' do
    before { create_production_request(client: client, musician: musician) }

    it 'returns requests for client' do
      get '/api/v1/production_requests', headers: auth_headers_for(client)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_requests'].length).to eq(1)
      expect(json['production_requests'].first['title']).to eq('BGM for short film')
    end

    it 'returns requests for musician' do
      get '/api/v1/production_requests', headers: auth_headers_for(musician)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_requests'].length).to eq(1)
    end
  end

  describe 'GET /api/v1/production_requests/:uuid' do
    let(:pr) { create_production_request(client: client, musician: musician) }

    it 'shows request to client' do
      get "/api/v1/production_requests/#{pr.uuid}", headers: auth_headers_for(client)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_request']['uuid']).to eq(pr.uuid)
    end

    it 'shows request to musician' do
      get "/api/v1/production_requests/#{pr.uuid}", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:ok)
    end

    it 'forbids non-participant' do
      other = User.create!(email: 'other@example.com', password: 'password123', name: 'Other', is_musician: true).reload
      get "/api/v1/production_requests/#{pr.uuid}", headers: auth_headers_for(other)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/production_requests/:uuid/accept' do
    let(:pr) { create_production_request(client: client, musician: musician) }

    it 'allows musician to accept' do
      post "/api/v1/production_requests/#{pr.uuid}/accept", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_request']['status']).to eq('accepted')
      expect(json['contract_uuid']).to be_present
      expect(json['conversation_uuid']).to be_present
      expect(pr.reload).to be_accepted
    end

    it 'forbids client from accepting' do
      post "/api/v1/production_requests/#{pr.uuid}/accept", headers: auth_headers_for(client)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/production_requests/:uuid/reject' do
    let(:pr) { create_production_request(client: client, musician: musician) }

    it 'allows musician to reject' do
      post "/api/v1/production_requests/#{pr.uuid}/reject", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_request']['status']).to eq('rejected')
    end

    it 'forbids client from rejecting' do
      post "/api/v1/production_requests/#{pr.uuid}/reject", headers: auth_headers_for(client)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents rejecting already accepted request' do
      pr.update!(status: 'accepted')
      post "/api/v1/production_requests/#{pr.uuid}/reject", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents rejecting withdrawn request' do
      pr.update!(status: 'withdrawn')
      post "/api/v1/production_requests/#{pr.uuid}/reject", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/production_requests/:uuid/withdraw' do
    let(:pr) { create_production_request(client: client, musician: musician) }

    it 'allows client to withdraw a pending request' do
      post "/api/v1/production_requests/#{pr.uuid}/withdraw", headers: auth_headers_for(client)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['production_request']['status']).to eq('withdrawn')
      expect(pr.reload).to be_withdrawn
    end

    it 'forbids withdrawal of accepted request' do
      pr.update!(status: 'accepted')
      post "/api/v1/production_requests/#{pr.uuid}/withdraw", headers: auth_headers_for(client)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'forbids musician from withdrawing' do
      post "/api/v1/production_requests/#{pr.uuid}/withdraw", headers: auth_headers_for(musician)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
