require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'new attributes' do
    it 'can save with provider and uid' do
      user = User.create!(
        email: 'github@example.com',
        password: 'password123',
        provider: 'github',
        uid: '12345'
      )
      expect(user.provider).to eq('github')
      expect(user.uid).to eq('12345')
    end

    it 'can save with bio' do
      user = User.create!(
        email: 'bio@example.com',
        password: 'password123',
        bio: 'I am a musician'
      )
      expect(user.bio).to eq('I am a musician')
    end

    it 'allows nil values for new fields' do
      user = User.create!(
        email: 'normal@example.com',
        password: 'password123'
      )
      expect(user.provider).to be_nil
      expect(user.uid).to be_nil
      expect(user.bio).to be_nil
    end

    it 'can save all new attributes together' do
      user = User.create!(
        email: 'complete@example.com',
        password: 'password123',
        provider: 'github',
        uid: '67890',
        bio: 'Full stack musician and developer'
      )
      expect(user.provider).to eq('github')
      expect(user.uid).to eq('67890')
      expect(user.bio).to eq('Full stack musician and developer')
    end
  end

  describe 'message associations' do
    let(:user) { User.create!(email: 'user@example.com', password: 'password123') }
    let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
    let(:commission) { Commission.create!(user: user, track: track, description: 'Test commission', budget: 5000, status: 'pending') }

    it 'has many messages' do
      message1 = user.messages.create!(commission: commission, content: 'First message')
      message2 = user.messages.create!(commission: commission, content: 'Second message')

      expect(user.messages.count).to eq(2)
      expect(user.messages).to include(message1, message2)
    end

    it 'destroys associated messages when user is deleted' do
      message = user.messages.create!(commission: commission, content: 'Test message')
      message_id = message.id

      user.destroy

      expect(Message.find_by(id: message_id)).to be_nil
    end

    it 'can send messages to different commissions' do
      commission2 = Commission.create!(user: user, track: track, description: 'Another commission', budget: 3000, status: 'pending')
      
      message1 = user.messages.create!(commission: commission, content: 'Message to first commission')
      message2 = user.messages.create!(commission: commission2, content: 'Message to second commission')

      expect(user.messages.count).to eq(2)
      expect(message1.commission).to eq(commission)
      expect(message2.commission).to eq(commission2)
    end
  end
end