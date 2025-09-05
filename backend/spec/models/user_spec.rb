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
end