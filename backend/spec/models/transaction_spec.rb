require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }
  let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'accepted') }
  let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000, status: 'active') }
  let(:milestone) { ContractMilestone.create!(contract: contract, title: 'First milestone', amount_jpy: 25000, status: 'open') }

  describe 'validations' do
    it 'creates a valid transaction with required fields' do
      tx = Transaction.create!(
        contract: contract,
        milestone: milestone,
        amount_jpy: 25000,
        kind: 'milestone_payout',
        status: 'authorized',
        provider: 'stripe',
        provider_ref: 'pi_123'
      )

      expect(tx.contract).to eq(contract)
      expect(tx.milestone).to eq(milestone)
      expect(tx.amount_jpy).to eq(25000)
      expect(tx.kind).to eq('milestone_payout')
      expect(tx.authorized?).to be true
    end

    it 'requires positive amount' do
      tx = Transaction.new(contract: contract, amount_jpy: 0, kind: 'escrow_deposit', status: 'authorized')
      expect(tx).not_to be_valid
      expect(tx.errors[:amount_jpy]).to be_present
    end

    it 'requires kind and applies default status when missing' do
      tx = Transaction.new(contract: contract, amount_jpy: 1000)
      expect(tx).not_to be_valid
      expect(tx.errors[:kind]).to be_present
      expect(tx.status).to eq('authorized')
    end
  end

  describe 'enums' do
    let!(:tx) { Transaction.create!(contract: contract, amount_jpy: 1000, kind: 'escrow_deposit', status: 'authorized') }

    it 'supports kind enum values' do
      tx.kind = 'refund'
      expect(tx.refund?).to be true
    end

    it 'supports status enum values' do
      tx.status = 'captured'
      expect(tx.captured?).to be true
    end
  end

  describe 'scopes' do
    let!(:tx_for_contract) { Transaction.create!(contract: contract, amount_jpy: 2000, kind: 'escrow_deposit', status: 'captured') }
    let!(:milestone_tx) { Transaction.create!(contract: contract, milestone: milestone, amount_jpy: 3000, kind: 'milestone_payout', status: 'paid_out') }

    it 'finds transactions for a contract' do
      expect(Transaction.for_contract(contract.id)).to include(tx_for_contract, milestone_tx)
    end

    it 'finds transactions for a milestone' do
      expect(Transaction.for_milestone(milestone.id)).to include(milestone_tx)
    end
  end

  describe 'uuid helpers' do
    let!(:tx) { Transaction.create!(contract: contract, amount_jpy: 1000, kind: 'platform_fee', status: 'failed').reload }

    it 'returns uuid in to_param' do
      expect(tx.to_param).to eq(tx.uuid)
    end

    it 'finds by uuid' do
      expect(Transaction.find_by_uuid(tx.uuid)).to eq(tx)
    end
  end
end
