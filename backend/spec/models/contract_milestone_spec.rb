require 'rails_helper'

RSpec.describe ContractMilestone, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }
  let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'accepted') }
  let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000, status: 'active') }

  describe 'validations' do
    it 'creates a valid contract_milestone with required fields' do
      milestone = ContractMilestone.create!(
        contract: contract,
        title: 'First milestone',
        amount_jpy: 25000,
        status: 'open'
      )

      expect(milestone.contract).to eq(contract)
      expect(milestone.title).to eq('First milestone')
      expect(milestone.amount_jpy).to eq(25000)
      expect(milestone.status).to eq('open')
    end

    it 'requires title' do
      milestone = ContractMilestone.new(contract: contract, amount_jpy: 25000)
      expect(milestone).not_to be_valid
      expect(milestone.errors[:title]).to be_present
    end

    it 'validates title length' do
      milestone = ContractMilestone.new(
        contract: contract,
        title: 'a' * 256,
        amount_jpy: 25000
      )
      expect(milestone).not_to be_valid
      expect(milestone.errors[:title]).to be_present
    end

    it 'requires amount_jpy' do
      milestone = ContractMilestone.new(contract: contract, title: 'Test milestone')
      expect(milestone).not_to be_valid
      expect(milestone.errors[:amount_jpy]).to be_present
    end

    it 'validates amount_jpy is positive' do
      milestone = ContractMilestone.new(
        contract: contract,
        title: 'Test milestone',
        amount_jpy: -1000
      )
      expect(milestone).not_to be_valid
      expect(milestone.errors[:amount_jpy]).to be_present
    end

    it 'requires status' do
      milestone = ContractMilestone.new(
        contract: contract,
        title: 'Test milestone',
        amount_jpy: 25000,
        status: nil
      )
      expect(milestone).not_to be_valid
      expect(milestone.errors[:status]).to be_present
    end

    it 'allows due_on to be optional' do
      milestone = ContractMilestone.create!(
        contract: contract,
        title: 'Test milestone',
        amount_jpy: 25000
      )
      expect(milestone.due_on).to be_nil
      expect(milestone).to be_valid
    end
  end

  describe 'enum status' do
    let(:milestone) { ContractMilestone.create!(contract: contract, title: 'Test milestone', amount_jpy: 25000) }

    it 'has open status by default' do
      expect(milestone.open?).to be true
    end

    it 'can change to submitted' do
      milestone.status = 'submitted'
      expect(milestone.submitted?).to be true
    end

    it 'can change to approved' do
      milestone.status = 'approved'
      expect(milestone.approved?).to be true
    end

    it 'can change to rejected' do
      milestone.status = 'rejected'
      expect(milestone.rejected?).to be true
    end

    it 'can change to paid' do
      milestone.status = 'paid'
      expect(milestone.paid?).to be true
    end
  end

  describe 'associations' do
    it 'belongs to contract' do
      milestone = ContractMilestone.create!(
        contract: contract,
        title: 'Test milestone',
        amount_jpy: 25000
      )
      expect(milestone.contract).to eq(contract)
    end
  end

  describe 'scopes' do
    let!(:milestone1) { ContractMilestone.create!(contract: contract, title: 'Milestone 1', amount_jpy: 10000, status: 'open') }
    let!(:milestone2) { ContractMilestone.create!(contract: contract, title: 'Milestone 2', amount_jpy: 15000, status: 'submitted') }
    let!(:milestone3) { ContractMilestone.create!(contract: contract, title: 'Milestone 3', amount_jpy: 25000, status: 'approved') }
    let!(:milestone4) { ContractMilestone.create!(contract: contract, title: 'Milestone 4', amount_jpy: 20000, status: 'paid') }

    let(:another_client) { User.create!(email: 'another_client@example.com', password: 'password123', is_client: true) }
    let(:another_musician) { User.create!(email: 'another_musician@example.com', password: 'password123', is_musician: true) }
    let(:another_job) { Job.create!(client: another_client, title: 'Another job', description: 'Test', status: 'published', published_at: Time.current) }
    let(:another_proposal) { Proposal.create!(job: another_job, musician: another_musician, quote_total_jpy: 60000, delivery_days: 10) }
    let(:another_contract) { Contract.create!(proposal: another_proposal, client: another_client, musician: another_musician, escrow_total_jpy: 60000) }
    let!(:another_milestone) { ContractMilestone.create!(contract: another_contract, title: 'Another milestone', amount_jpy: 30000, status: 'open') }

    it 'returns milestones for a specific contract' do
      expect(ContractMilestone.for_contract(contract.id)).to include(milestone1, milestone2, milestone3, milestone4)
      expect(ContractMilestone.for_contract(contract.id)).not_to include(another_milestone)
    end

    it 'returns open milestones' do
      expect(ContractMilestone.open).to include(milestone1, another_milestone)
      expect(ContractMilestone.open).not_to include(milestone2, milestone3, milestone4)
    end

    it 'returns submitted milestones' do
      expect(ContractMilestone.submitted).to include(milestone2)
      expect(ContractMilestone.submitted).not_to include(milestone1, milestone3, milestone4)
    end

    it 'returns approved milestones' do
      expect(ContractMilestone.approved).to include(milestone3)
      expect(ContractMilestone.approved).not_to include(milestone1, milestone2, milestone4)
    end

    it 'returns paid milestones' do
      expect(ContractMilestone.paid).to include(milestone4)
      expect(ContractMilestone.paid).not_to include(milestone1, milestone2, milestone3)
    end
  end

  describe 'default values' do
    it 'sets default status to open' do
      milestone = ContractMilestone.create!(
        contract: contract,
        title: 'Test milestone',
        amount_jpy: 25000
      )
      expect(milestone.status).to eq('open')
    end
  end
end
