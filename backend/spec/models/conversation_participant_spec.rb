require 'rails_helper'

RSpec.describe ConversationParticipant, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
  let(:job) { Job.create!(client: user, track: track, title: 'Test Job', description: 'Test description', status: 'draft') }
  let(:conversation) { Conversation.create!(job: job) }

  describe 'associations' do
    it 'belongs to conversation' do
      participant = ConversationParticipant.new(conversation: conversation, user: user)
      expect(participant.conversation).to eq(conversation)
    end

    it 'belongs to user' do
      participant = ConversationParticipant.new(conversation: conversation, user: user)
      expect(participant.user).to eq(user)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to conversation_id' do
      ConversationParticipant.create!(conversation: conversation, user: user)
      duplicate = ConversationParticipant.new(conversation: conversation, user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end
  end

  describe '#to_param' do
    it 'returns the UUID' do
      participant = ConversationParticipant.create!(conversation: conversation, user: user)
      expect(participant.to_param).to eq(participant.id.to_s)
    end
  end

  describe '#mark_as_read!' do
    it 'updates last_read_at to current time' do
      participant = ConversationParticipant.create!(conversation: conversation, user: user, last_read_at: nil)

      expect {
        participant.mark_as_read!
      }.to change { participant.reload.last_read_at }.from(nil)

      expect(participant.last_read_at).to be_within(1.second).of(Time.current)
    end

    it 'updates existing last_read_at' do
      old_time = 1.hour.ago
      participant = ConversationParticipant.create!(conversation: conversation, user: user, last_read_at: old_time)

      participant.mark_as_read!

      expect(participant.reload.last_read_at).to be > old_time
      expect(participant.last_read_at).to be_within(1.second).of(Time.current)
    end
  end
end
