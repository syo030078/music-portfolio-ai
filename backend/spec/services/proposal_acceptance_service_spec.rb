require 'rails_helper'

RSpec.describe ProposalAcceptanceService do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) do
    Job.create!(
      client: client,
      title: 'Need a remix',
      description: 'Test description',
      status: 'published',
      published_at: Time.current
    )
  end
  let(:proposal) do
    Proposal.create!(
      job: job,
      musician: musician,
      quote_total_jpy: 50_000,
      delivery_days: 7,
      cover_message: 'よろしくお願いします'
    )
  end

  describe '.call' do
    it 'accepts proposal and creates contract and conversation' do
      result = described_class.call(proposal: proposal, actor: client)

      expect(result.success?).to be true
      expect(result.contract).to be_present
      expect(result.conversation).to be_present

      proposal.reload
      job.reload

      expect(proposal).to be_accepted
      expect(job).to be_contracted
      expect(result.contract.client_id).to eq(client.id)
      expect(result.contract.musician_id).to eq(musician.id)
      expect(result.contract.escrow_total_jpy).to eq(proposal.quote_total_jpy)
      expect(result.conversation.contract_id).to eq(result.contract.id)

      participant_ids = result.conversation.participants.pluck(:id)
      expect(participant_ids).to contain_exactly(client.id, musician.id)
    end

    it 'rejects when actor is not job owner' do
      result = described_class.call(proposal: proposal, actor: musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
      expect(proposal.reload.status).to eq('submitted')
    end

    it 'rejects when job already has a contract' do
      other_musician = User.create!(email: 'musician2@example.com', password: 'password123', is_musician: true)
      other_proposal = Proposal.create!(
        job: job,
        musician: other_musician,
        quote_total_jpy: 60_000,
        delivery_days: 10
      )
      Contract.create!(
        proposal: other_proposal,
        client: client,
        musician: other_musician,
        escrow_total_jpy: other_proposal.quote_total_jpy,
        status: 'active'
      )

      result = described_class.call(proposal: proposal, actor: client)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
      expect(proposal.reload.status).to eq('submitted')
    end

    it 'rolls back when contract creation fails' do
      allow(Contract).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Contract.new))

      result = described_class.call(proposal: proposal, actor: client)

      expect(result.success?).to be false
      expect(proposal.reload.status).to eq('submitted')
      expect(job.reload.status).to eq('published')
    end
  end
end
