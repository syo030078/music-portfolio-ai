require 'rails_helper'

RSpec.describe Contract, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }
  let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'accepted') }

  describe 'validations' do
    it 'creates a valid contract with required fields' do
      contract = Contract.create!(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 50000,
        status: 'active'
      )

      expect(contract.proposal).to eq(proposal)
      expect(contract.client).to eq(client)
      expect(contract.musician).to eq(musician)
      expect(contract.escrow_total_jpy).to eq(50000)
      expect(contract.status).to eq('active')
    end

    it 'requires escrow_total_jpy' do
      contract = Contract.new(proposal: proposal, client: client, musician: musician)
      expect(contract).not_to be_valid
      expect(contract.errors[:escrow_total_jpy]).to be_present
    end

    it 'validates escrow_total_jpy is positive' do
      contract = Contract.new(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: -1000
      )
      expect(contract).not_to be_valid
      expect(contract.errors[:escrow_total_jpy]).to be_present
    end

    it 'requires status' do
      contract = Contract.new(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 50000,
        status: nil
      )
      expect(contract).not_to be_valid
      expect(contract.errors[:status]).to be_present
    end

    it 'prevents duplicate contract for same proposal' do
      Contract.create!(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 50000
      )

      duplicate = Contract.new(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 60000
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:proposal_id]).to be_present
    end
  end

  describe 'enum status' do
    let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000) }

    it 'has active status by default' do
      expect(contract.active?).to be true
    end

    it 'can change to in_progress' do
      contract.status = 'in_progress'
      expect(contract.in_progress?).to be true
    end

    it 'can change to delivered' do
      contract.status = 'delivered'
      expect(contract.delivered?).to be true
    end

    it 'can change to completed' do
      contract.status = 'completed'
      expect(contract.completed?).to be true
    end

    it 'can change to canceled' do
      contract.status = 'canceled'
      expect(contract.canceled?).to be true
    end
  end

  describe 'associations' do
    let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000) }

    it 'belongs to proposal' do
      expect(contract.proposal).to eq(proposal)
    end

    it 'belongs to client' do
      expect(contract.client).to eq(client)
    end

    it 'belongs to musician' do
      expect(contract.musician).to eq(musician)
    end

    it 'has many contract_milestones' do
      milestone1 = contract.contract_milestones.create!(
        title: 'First milestone',
        amount_jpy: 25000,
        status: 'open'
      )
      milestone2 = contract.contract_milestones.create!(
        title: 'Second milestone',
        amount_jpy: 25000,
        status: 'open'
      )

      expect(contract.contract_milestones.count).to eq(2)
      expect(contract.contract_milestones).to include(milestone1, milestone2)
    end

    it 'destroys associated contract_milestones when contract is deleted' do
      milestone = contract.contract_milestones.create!(
        title: 'Test milestone',
        amount_jpy: 50000,
        status: 'open'
      )
      milestone_id = milestone.id

      contract.destroy

      expect(ContractMilestone.find_by(id: milestone_id)).to be_nil
    end
  end

  describe 'scopes' do
    let!(:contract1) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000, status: 'active') }

    let(:another_client) { User.create!(email: 'another_client@example.com', password: 'password123', is_client: true) }
    let(:another_musician) { User.create!(email: 'another_musician@example.com', password: 'password123', is_musician: true) }
    let(:another_job) { Job.create!(client: another_client, title: 'Another job', description: 'Test', status: 'published', published_at: Time.current) }
    let(:another_proposal) { Proposal.create!(job: another_job, musician: another_musician, quote_total_jpy: 60000, delivery_days: 10) }
    let!(:contract2) { Contract.create!(proposal: another_proposal, client: another_client, musician: another_musician, escrow_total_jpy: 60000, status: 'in_progress') }

    it 'returns contracts for a specific client' do
      expect(Contract.for_client(client.id)).to include(contract1)
      expect(Contract.for_client(client.id)).not_to include(contract2)
    end

    it 'returns contracts for a specific musician' do
      expect(Contract.for_musician(musician.id)).to include(contract1)
      expect(Contract.for_musician(musician.id)).not_to include(contract2)
    end

    it 'returns active contracts' do
      expect(Contract.active).to include(contract1)
      expect(Contract.active).not_to include(contract2)
    end

    it 'returns in_progress contracts' do
      expect(Contract.in_progress).to include(contract2)
      expect(Contract.in_progress).not_to include(contract1)
    end
  end

  describe 'default values' do
    it 'sets default status to active' do
      contract = Contract.create!(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 50000
      )
      expect(contract.status).to eq('active')
    end
  end
end
