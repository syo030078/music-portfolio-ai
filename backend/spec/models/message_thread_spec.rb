require 'rails_helper'

RSpec.describe MessageThread, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true).reload }
  let(:job) { Job.create!(client: client, title: 'Test job', description: 'Test', status: 'published', published_at: Time.current).reload }
  let(:contract) do
    proposal = Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7).reload
    Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000).reload
  end

  describe 'associations' do
    it { should belong_to(:job).optional }
    it { should belong_to(:contract).optional }
    it { should have_many(:participants) }
    it { should have_many(:users).through(:participants) }
    it { should have_many(:messages) }
  end

  describe 'validations' do
    context 'with job' do
      let(:thread) { MessageThread.create!(job: job).reload }

      it 'is valid with job_id' do
        expect(thread).to be_valid
      end

      it 'generates UUID on creation' do
        expect(thread.uuid).to be_present
        expect(thread.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      end

      it 'returns UUID in to_param' do
        expect(thread.to_param).to eq(thread.uuid)
      end

      it 'finds thread by UUID' do
        found = MessageThread.find_by_uuid(thread.uuid)
        expect(found).to eq(thread)
      end
    end

    context 'with contract' do
      let(:thread) { MessageThread.create!(contract: contract).reload }

      it 'is valid with contract_id' do
        expect(thread).to be_valid
      end
    end

    context 'without job or contract' do
      let(:thread) { MessageThread.new }

      it 'is invalid without job or contract' do
        expect(thread).not_to be_valid
        expect(thread.errors[:base]).to include('must have either job or contract')
      end
    end

    context 'with both job and contract' do
      let(:thread) { MessageThread.new(job: job, contract: contract) }

      it 'is invalid with both job and contract' do
        expect(thread).not_to be_valid
        expect(thread.errors[:base]).to include('cannot have both job and contract')
      end
    end
  end
end
