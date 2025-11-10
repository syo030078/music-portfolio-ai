require 'rails_helper'

RSpec.describe 'UUID Support', type: :model do
  describe User do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

    it 'generates UUID on creation' do
      expect(user.uuid).to be_present
      expect(user.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    it 'has unique UUID' do
      user2 = User.create!(email: 'test2@example.com', password: 'password123')
      expect(user.uuid).not_to eq(user2.uuid)
    end

    it 'returns UUID in to_param' do
      expect(user.to_param).to eq(user.uuid)
    end

    it 'finds user by UUID' do
      found = User.find_by_uuid(user.uuid)
      expect(found).to eq(user)
    end
  end

  describe Proposal do
    let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
    let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
    let(:job) { Job.create!(client: client, title: 'Test job', description: 'Test', status: 'published', published_at: Time.current) }
    let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7) }

    it 'generates UUID on creation' do
      expect(proposal.uuid).to be_present
      expect(proposal.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    it 'returns UUID in to_param' do
      expect(proposal.to_param).to eq(proposal.uuid)
    end

    it 'finds proposal by UUID' do
      found = Proposal.find_by_uuid(proposal.uuid)
      expect(found).to eq(proposal)
    end
  end

  describe Contract do
    let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
    let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
    let(:job) { Job.create!(client: client, title: 'Test job', description: 'Test', status: 'published', published_at: Time.current) }
    let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7) }
    let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000) }

    it 'generates UUID on creation' do
      expect(contract.uuid).to be_present
      expect(contract.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    it 'returns UUID in to_param' do
      expect(contract.to_param).to eq(contract.uuid)
    end

    it 'finds contract by UUID' do
      found = Contract.find_by_uuid(contract.uuid)
      expect(found).to eq(contract)
    end
  end

  describe Job do
    let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
    let(:job) { Job.create!(client: client, title: 'Test job', description: 'Test', status: 'draft') }

    it 'generates UUID on creation' do
      expect(job.uuid).to be_present
      expect(job.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    it 'returns UUID in to_param' do
      expect(job.to_param).to eq(job.uuid)
    end

    it 'finds job by UUID' do
      found = Job.find_by_uuid(job.uuid)
      expect(found).to eq(job)
    end
  end
end
