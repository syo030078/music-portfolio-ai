require 'rails_helper'

RSpec.describe Conversation, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
  let(:job) { Job.create!(client: user, track: track, title: 'Test Job', description: 'Test description', status: 'published', published_at: Time.current) }

  describe 'associations' do
    it 'belongs to job' do
      conversation = Conversation.new(job: job)
      expect(conversation.job).to eq(job)
    end

    it 'belongs to contract' do
      proposal = Proposal.create!(job: job, musician: musician, cover_message: 'Test', quote_total_jpy: 10000, delivery_days: 7)
      contract = Contract.create!(proposal: proposal, client: user, musician: musician, escrow_total_jpy: 10000)
      conversation = Conversation.new(contract: contract)
      expect(conversation.contract).to eq(contract)
    end

    it 'has many conversation_participants' do
      conversation = Conversation.create!(job: job)
      expect(conversation).to respond_to(:conversation_participants)
    end

    it 'has many participants through conversation_participants' do
      conversation = Conversation.create!(job: job)
      expect(conversation).to respond_to(:participants)
    end

    it 'has many messages' do
      conversation = Conversation.create!(job: job)
      expect(conversation).to respond_to(:messages)
    end
  end

  describe 'validations' do
    context 'when job_id is present' do
      it 'does not require contract_id' do
        conversation = Conversation.new(job: job, contract: nil)
        expect(conversation).to be_valid
      end

      it 'rejects contract_id presence' do
        proposal = Proposal.create!(job: job, musician: musician, cover_message: 'Test', quote_total_jpy: 10000, delivery_days: 7)
        contract = Contract.create!(proposal: proposal, client: user, musician: musician, escrow_total_jpy: 10000)
        conversation = Conversation.new(job: job, contract: contract)
        expect(conversation).not_to be_valid
        expect(conversation.errors[:base]).to include('Cannot belong to both job and contract')
      end
    end

    context 'when contract_id is present' do
      it 'does not require job_id' do
        proposal = Proposal.create!(job: job, musician: musician, cover_message: 'Test', quote_total_jpy: 10000, delivery_days: 7)
        contract = Contract.create!(proposal: proposal, client: user, musician: musician, escrow_total_jpy: 10000)
        conversation = Conversation.new(job: nil, contract: contract)
        expect(conversation).to be_valid
      end
    end

    context 'when both job_id and contract_id are nil' do
      it 'is invalid' do
        conversation = Conversation.new(job: nil, contract: nil)
        expect(conversation).not_to be_valid
        expect(conversation.errors[:job_id]).to include("can't be blank")
      end
    end
  end

  describe '#to_param' do
    it 'returns the UUID' do
      conversation = Conversation.create!(job: job)
      expect(conversation.to_param).to eq(conversation.id.to_s)
    end
  end

  describe '.find_by_uuid' do
    it 'finds conversation by UUID' do
      conversation = Conversation.create!(job: job)
      found = Conversation.find_by_uuid(conversation.id)
      expect(found).to eq(conversation)
    end
  end

  describe '#participant?' do
    it 'returns true if user is a participant' do
      conversation = Conversation.create!(job: job)
      participant_user = User.create!(email: 'participant@example.com', password: 'password123')
      ConversationParticipant.create!(conversation: conversation, user: participant_user)

      expect(conversation.participant?(participant_user)).to be true
    end

    it 'returns false if user is not a participant' do
      conversation = Conversation.create!(job: job)
      non_participant = User.create!(email: 'nonparticipant@example.com', password: 'password123')

      expect(conversation.participant?(non_participant)).to be false
    end
  end

  describe '#unread_count_for' do
    it 'returns 0 when user is not a participant' do
      conversation = Conversation.create!(job: job)
      non_participant = User.create!(email: 'nonparticipant@example.com', password: 'password123')

      expect(conversation.unread_count_for(non_participant)).to eq(0)
    end

    it 'returns all messages when last_read_at is nil' do
      conversation = Conversation.create!(job: job)
      participant_user = User.create!(email: 'participant@example.com', password: 'password123')
      participant = ConversationParticipant.create!(conversation: conversation, user: participant_user)

      sender = User.create!(email: 'sender@example.com', password: 'password123')
      3.times { Message.create!(conversation: conversation, sender: sender, body: 'Test message') }

      expect(conversation.unread_count_for(participant_user)).to eq(3)
    end

    it 'returns messages created after last_read_at' do
      conversation = Conversation.create!(job: job)
      participant_user = User.create!(email: 'participant@example.com', password: 'password123')
      participant = ConversationParticipant.create!(conversation: conversation, user: participant_user, last_read_at: 1.hour.ago)

      sender = User.create!(email: 'sender@example.com', password: 'password123')
      Message.create!(conversation: conversation, sender: sender, body: 'Old message', created_at: 2.hours.ago)
      2.times { Message.create!(conversation: conversation, sender: sender, body: 'New message', created_at: 30.minutes.ago) }

      expect(conversation.unread_count_for(participant_user)).to eq(2)
    end
  end

  describe '#parent' do
    it 'returns job when conversation belongs to job' do
      conversation = Conversation.create!(job: job, contract: nil)
      expect(conversation.parent).to eq(job)
    end

    it 'returns contract when conversation belongs to contract' do
      proposal = Proposal.create!(job: job, musician: musician, cover_message: 'Test', quote_total_jpy: 10000, delivery_days: 7)
      contract = Contract.create!(proposal: proposal, client: user, musician: musician, escrow_total_jpy: 10000)
      conversation = Conversation.create!(job: nil, contract: contract)
      expect(conversation.parent).to eq(contract)
    end
  end
end
