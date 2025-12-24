require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
  let(:job) { Job.create!(client: user, track: track, title: 'Test Job', description: 'Test description', status: 'draft') }
  let(:conversation) { Conversation.create!(job: job) }
  let(:sender) { User.create!(email: 'sender@example.com', password: 'password123') }

  describe 'associations' do
    it 'belongs to conversation' do
      message = Message.new(conversation: conversation, sender: sender, content: 'Test')
      expect(message.conversation).to eq(conversation)
    end

    it 'belongs to sender' do
      message = Message.new(conversation: conversation, sender: sender, content: 'Test')
      expect(message.sender).to eq(sender)
    end
  end

  describe 'validations' do
    it 'requires content to be present' do
      message = Message.new(conversation: conversation, sender: sender, content: '')
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    it 'requires content to be at least 1 character' do
      message = Message.new(conversation: conversation, sender: sender, content: '')
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("is too short (minimum is 1 character)")
    end

    it 'requires content to be at most 1000 characters' do
      long_content = 'a' * 1001
      message = Message.new(conversation: conversation, sender: sender, content: long_content)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("is too long (maximum is 1000 characters)")
    end
  end

  describe '#to_param' do
    it 'returns the UUID' do
      message = Message.create!(conversation: conversation, sender: sender, content: 'Test message')
      expect(message.to_param).to eq(message.uuid)
    end
  end

  describe 'after_create callback' do
    it 'marks sender as read when message is created' do
      participant = ConversationParticipant.create!(conversation: conversation, user: sender, last_read_at: nil)

      message = Message.create!(conversation: conversation, sender: sender, content: 'Test message')

      expect(participant.reload.last_read_at).to be_within(1.second).of(Time.current)
    end

    it 'does not fail when sender is not a participant' do
      expect {
        Message.create!(conversation: conversation, sender: sender, content: 'Test message')
      }.not_to raise_error
    end
  end
end
