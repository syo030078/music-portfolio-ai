require 'rails_helper'

RSpec.describe Proposal, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }

  describe 'validations' do
    it 'creates a valid proposal with required fields' do
      proposal = Proposal.create!(
        job: job,
        musician: musician,
        quote_total_jpy: 50000,
        delivery_days: 7,
        status: 'submitted'
      )

      expect(proposal.job).to eq(job)
      expect(proposal.musician).to eq(musician)
      expect(proposal.quote_total_jpy).to eq(50000)
      expect(proposal.delivery_days).to eq(7)
      expect(proposal.status).to eq('submitted')
    end

    it 'requires quote_total_jpy' do
      proposal = Proposal.new(job: job, musician: musician, delivery_days: 7)
      expect(proposal).not_to be_valid
      expect(proposal.errors[:quote_total_jpy]).to be_present
    end

    it 'validates quote_total_jpy is positive' do
      proposal = Proposal.new(job: job, musician: musician, quote_total_jpy: -1000, delivery_days: 7)
      expect(proposal).not_to be_valid
      expect(proposal.errors[:quote_total_jpy]).to be_present
    end

    it 'requires delivery_days' do
      proposal = Proposal.new(job: job, musician: musician, quote_total_jpy: 50000)
      expect(proposal).not_to be_valid
      expect(proposal.errors[:delivery_days]).to be_present
    end

    it 'validates delivery_days is positive' do
      proposal = Proposal.new(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: -1)
      expect(proposal).not_to be_valid
      expect(proposal.errors[:delivery_days]).to be_present
    end

    it 'validates delivery_days is an integer' do
      proposal = Proposal.new(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7.5)
      expect(proposal).not_to be_valid
      expect(proposal.errors[:delivery_days]).to be_present
    end

    it 'validates cover_message length' do
      proposal = Proposal.new(
        job: job,
        musician: musician,
        cover_message: 'a' * 2001,
        quote_total_jpy: 50000,
        delivery_days: 7
      )
      expect(proposal).not_to be_valid
      expect(proposal.errors[:cover_message]).to be_present
    end

    it 'allows cover_message to be blank' do
      proposal = Proposal.create!(
        job: job,
        musician: musician,
        quote_total_jpy: 50000,
        delivery_days: 7
      )
      expect(proposal.cover_message).to be_nil
      expect(proposal).to be_valid
    end

    it 'prevents musician from submitting proposal to own job' do
      own_job = Job.create!(
        client: musician,
        title: 'My own job',
        description: 'Test',
        status: 'published',
        published_at: Time.current
      )

      proposal = Proposal.new(
        job: own_job,
        musician: musician,
        quote_total_jpy: 50000,
        delivery_days: 7
      )
      expect(proposal).not_to be_valid
      expect(proposal.errors[:musician_id]).to be_present
    end

    it 'prevents proposal to draft job' do
      draft_job = Job.create!(
        client: client,
        title: 'Draft job',
        description: 'Test',
        status: 'draft'
      )

      proposal = Proposal.new(
        job: draft_job,
        musician: musician,
        quote_total_jpy: 50000,
        delivery_days: 7
      )
      expect(proposal).not_to be_valid
      expect(proposal.errors[:job]).to be_present
    end

    it 'prevents duplicate proposal from same musician to same job' do
      Proposal.create!(
        job: job,
        musician: musician,
        quote_total_jpy: 50000,
        delivery_days: 7
      )

      duplicate = Proposal.new(
        job: job,
        musician: musician,
        quote_total_jpy: 60000,
        delivery_days: 10
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:musician_id]).to be_present
    end
  end

  describe 'enum status' do
    let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7) }

    it 'has submitted status by default' do
      expect(proposal.submitted?).to be true
    end

    it 'can change to shortlisted' do
      proposal.status = 'shortlisted'
      expect(proposal.shortlisted?).to be true
    end

    it 'can change to accepted' do
      proposal.status = 'accepted'
      expect(proposal.accepted?).to be true
    end

    it 'can change to rejected' do
      proposal.status = 'rejected'
      expect(proposal.rejected?).to be true
    end

    it 'can change to withdrawn' do
      proposal.status = 'withdrawn'
      expect(proposal.withdrawn?).to be true
    end
  end

  describe 'associations' do
    it 'belongs to job' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7)
      expect(proposal.job).to eq(job)
    end

    it 'belongs to musician' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7)
      expect(proposal.musician).to eq(musician)
    end

    it 'has one contract' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7)
      expect(proposal).to respond_to(:contract)
    end

    it 'destroys associated contract when proposal is deleted' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7)
      contract = Contract.create!(
        proposal: proposal,
        client: client,
        musician: musician,
        escrow_total_jpy: 50000,
        status: 'active'
      )
      contract_id = contract.id

      proposal.destroy

      expect(Contract.find_by(id: contract_id)).to be_nil
    end
  end

  describe 'scopes' do
    let!(:proposal1) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'submitted') }
    let!(:proposal2) { Proposal.create!(job: job, musician: User.create!(email: 'musician2@example.com', password: 'password123'), quote_total_jpy: 60000, delivery_days: 10, status: 'shortlisted') }
    let!(:proposal3) { Proposal.create!(job: job, musician: User.create!(email: 'musician3@example.com', password: 'password123'), quote_total_jpy: 70000, delivery_days: 14, status: 'accepted') }

    it 'returns proposals for a specific job' do
      another_job = Job.create!(
        client: client,
        title: 'Another job',
        description: 'Test',
        status: 'published',
        published_at: Time.current
      )
      another_proposal = Proposal.create!(
        job: another_job,
        musician: musician,
        quote_total_jpy: 80000,
        delivery_days: 20
      )

      expect(Proposal.for_job(job.id)).to include(proposal1, proposal2, proposal3)
      expect(Proposal.for_job(job.id)).not_to include(another_proposal)
    end

    it 'returns proposals by a specific musician' do
      expect(Proposal.by_musician(musician.id)).to include(proposal1)
      expect(Proposal.by_musician(musician.id)).not_to include(proposal2, proposal3)
    end

    it 'returns submitted proposals' do
      expect(Proposal.submitted).to include(proposal1)
      expect(Proposal.submitted).not_to include(proposal2, proposal3)
    end

    it 'returns shortlisted proposals' do
      expect(Proposal.shortlisted).to include(proposal2)
      expect(Proposal.shortlisted).not_to include(proposal1, proposal3)
    end

    it 'returns accepted proposals' do
      expect(Proposal.accepted).to include(proposal3)
      expect(Proposal.accepted).not_to include(proposal1, proposal2)
    end
  end

  describe 'default values' do
    it 'sets default status to submitted' do
      proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7)
      expect(proposal.status).to eq('submitted')
    end
  end
end
