# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Jobs', type: :request do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', name: 'Test Client', is_client: true) }

  let!(:published_job) do
    Job.create!(
      client: client,
      title: 'Published Job',
      description: 'A published job description',
      budget_jpy: 50_000,
      budget_min_jpy: 30_000,
      budget_max_jpy: 70_000,
      is_remote: true,
      status: 'published',
      published_at: Time.current
    ).reload
  end

  let!(:draft_job) do
    Job.create!(
      client: client,
      title: 'Draft Job',
      description: 'A draft job description',
      budget_jpy: 40_000,
      status: 'draft'
    ).reload
  end

  describe 'GET /api/v1/jobs' do
    it 'returns only published jobs' do
      get '/api/v1/jobs'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['jobs'].length).to eq(1)
    end

    it 'returns jobs with uuid instead of id' do
      get '/api/v1/jobs'

      json = JSON.parse(response.body)
      job = json['jobs'].first

      expect(job).to have_key('uuid')
      expect(job).not_to have_key('id')
      expect(job['uuid']).to eq(published_job.uuid)
    end

    it 'returns client with uuid instead of id' do
      client.reload
      get '/api/v1/jobs'

      json = JSON.parse(response.body)
      client_data = json['jobs'].first['client']

      expect(client_data).to have_key('uuid')
      expect(client_data).not_to have_key('id')
      expect(client_data['uuid']).to eq(client.uuid)
    end

    it 'includes all required job fields' do
      get '/api/v1/jobs'

      json = JSON.parse(response.body)
      job = json['jobs'].first

      expect(job).to include(
        'uuid' => published_job.uuid,
        'title' => 'Published Job',
        'description' => 'A published job description',
        'budget_jpy' => 50_000,
        'budget_min_jpy' => 30_000,
        'budget_max_jpy' => 70_000,
        'is_remote' => true
      )
      expect(job['published_at']).to be_present
    end
  end

  describe 'GET /api/v1/jobs/:uuid' do
    context 'with valid uuid' do
      it 'returns the job' do
        get "/api/v1/jobs/#{published_job.uuid}"

        expect(response).to have_http_status(:ok)
      end

      it 'returns job with uuid instead of id' do
        get "/api/v1/jobs/#{published_job.uuid}"

        json = JSON.parse(response.body)
        job = json['job']

        expect(job).to have_key('uuid')
        expect(job).not_to have_key('id')
        expect(job['uuid']).to eq(published_job.uuid)
      end

      it 'returns client with uuid instead of id' do
        client.reload
        get "/api/v1/jobs/#{published_job.uuid}"

        json = JSON.parse(response.body)
        client_data = json['job']['client']

        expect(client_data).to have_key('uuid')
        expect(client_data).not_to have_key('id')
        expect(client_data['uuid']).to eq(client.uuid)
      end

      it 'includes all required job fields' do
        get "/api/v1/jobs/#{published_job.uuid}"

        json = JSON.parse(response.body)
        job = json['job']

        expect(job).to include(
          'uuid' => published_job.uuid,
          'title' => 'Published Job',
          'description' => 'A published job description',
          'budget_jpy' => 50_000,
          'budget_min_jpy' => 30_000,
          'budget_max_jpy' => 70_000,
          'is_remote' => true
        )
        expect(job['published_at']).to be_present
        expect(job['created_at']).to be_present
        expect(job['delivery_due_on']).to be_nil
      end
    end

    context 'with invalid uuid' do
      it 'returns 404 for non-existent uuid' do
        get '/api/v1/jobs/non-existent-uuid'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'returns 404 for draft job uuid' do
        get "/api/v1/jobs/#{draft_job.uuid}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
