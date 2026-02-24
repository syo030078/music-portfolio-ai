require 'rails_helper'

RSpec.describe ProductionRequestAcceptanceService do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:other_musician) { User.create!(email: 'other@example.com', password: 'password123', is_musician: true) }

  let(:production_request) do
    ProductionRequest.create!(
      client: client,
      musician: musician,
      title: 'BGM for short film',
      description: 'Need atmospheric ambient music',
      budget_jpy: 80_000,
      delivery_days: 14
    )
  end

  describe '.call' do
    it 'accepts request and creates contract and conversation' do
      result = described_class.call(production_request: production_request, actor: musician)

      expect(result.success?).to be true
      expect(result.contract).to be_present
      expect(result.conversation).to be_present

      production_request.reload
      expect(production_request).to be_accepted
      expect(result.contract.client_id).to eq(client.id)
      expect(result.contract.musician_id).to eq(musician.id)
      expect(result.contract.escrow_total_jpy).to eq(80_000)
      expect(result.contract.production_request_id).to eq(production_request.id)
      expect(result.contract.proposal_id).to be_nil
      expect(result.conversation.contract_id).to eq(result.contract.id)

      participant_ids = result.conversation.participants.pluck(:id)
      expect(participant_ids).to contain_exactly(client.id, musician.id)
    end

    it 'rejects when actor is not the addressed musician' do
      result = described_class.call(production_request: production_request, actor: client)

      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
      expect(production_request.reload).to be_pending
    end

    it 'rejects when actor is a different musician' do
      result = described_class.call(production_request: production_request, actor: other_musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
    end

    it 'rejects when already accepted' do
      production_request.update!(status: 'accepted')
      result = described_class.call(production_request: production_request, actor: musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end

    it 'rejects when already rejected' do
      production_request.update!(status: 'rejected')
      result = described_class.call(production_request: production_request, actor: musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end

    it 'rejects when already withdrawn' do
      production_request.update!(status: 'withdrawn')
      result = described_class.call(production_request: production_request, actor: musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end

    it 'rolls back all changes when contract creation fails' do
      allow(Contract).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Contract.new))

      result = described_class.call(production_request: production_request, actor: musician)

      expect(result.success?).to be false
      expect(production_request.reload).to be_pending
      expect(Contract.count).to eq(0)
    end
  end
end
