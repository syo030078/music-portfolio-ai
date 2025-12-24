require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'validates timezone is a valid timezone' do
      user = User.new(email: 'test@example.com', password: 'password123', timezone: 'Invalid/Timezone')
      expect(user).not_to be_valid
      expect(user.errors[:timezone]).to include('is not included in the list')
    end

    it 'allows valid timezone' do
      user = User.new(email: 'test@example.com', password: 'password123', timezone: 'Tokyo')
      expect(user).to be_valid
    end

    it 'allows nil timezone' do
      user = User.new(email: 'test@example.com', password: 'password123', timezone: nil)
      expect(user).to be_valid
    end

    it 'validates display_name length' do
      user = User.new(email: 'test@example.com', password: 'password123', display_name: 'a' * 51)
      expect(user).not_to be_valid
      expect(user.errors[:display_name]).to include('is too long (maximum is 50 characters)')
    end

    it 'allows blank display_name' do
      user = User.new(email: 'test@example.com', password: 'password123', display_name: '')
      expect(user).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_user) { User.create!(email: 'active@example.com', password: 'password123') }
    let!(:deleted_user) { User.create!(email: 'deleted@example.com', password: 'password123', deleted_at: Time.current) }
    let!(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
    let!(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }

    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user, musician, client)
        expect(User.active).not_to include(deleted_user)
      end
    end

    describe '.musicians' do
      it 'returns only musicians' do
        expect(User.musicians).to eq([musician])
      end
    end

    describe '.clients' do
      it 'returns only clients' do
        expect(User.clients).to eq([client])
      end
    end
  end

  describe '#soft_delete' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

    it 'sets deleted_at timestamp' do
      expect(user.deleted_at).to be_nil
      user.soft_delete
      expect(user.deleted_at).not_to be_nil
    end
  end

  describe '#active?' do
    it 'returns true when deleted_at is nil' do
      user = User.create!(email: 'test@example.com', password: 'password123')
      expect(user.active?).to be true
    end

    it 'returns false when deleted_at is set' do
      user = User.create!(email: 'test@example.com', password: 'password123', deleted_at: Time.current)
      expect(user.active?).to be false
    end
  end

  describe 'default values' do
    it 'sets default timezone to UTC' do
      user = User.create!(email: 'test@example.com', password: 'password123')
      expect(user.timezone).to eq('UTC')
    end

    it 'sets default is_musician to false' do
      user = User.create!(email: 'test@example.com', password: 'password123')
      expect(user.is_musician).to be false
    end

    it 'sets default is_client to false' do
      user = User.create!(email: 'test@example.com', password: 'password123')
      expect(user.is_client).to be false
    end
  end

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
    let(:job) { Job.create!(client: user, track: track, title: 'Test Job', description: 'Test job', status: 'published', published_at: Time.current) }
    let(:conversation) { Conversation.create!(job: job) }

    it 'has many sent_messages' do
      message1 = user.sent_messages.create!(conversation: conversation, content: 'First message')
      message2 = user.sent_messages.create!(conversation: conversation, content: 'Second message')

      expect(user.sent_messages.count).to eq(2)
      expect(user.sent_messages).to include(message1, message2)
    end

    it 'destroys associated sent_messages when user is deleted' do
      message = user.sent_messages.create!(conversation: conversation, content: 'Test message')
      message_id = message.id

      user.destroy

      expect(Message.find_by(id: message_id)).to be_nil
    end

    it 'can send messages to different conversations' do
      job2 = Job.create!(client: user, track: track, title: 'Another Job', description: 'Another job', status: 'published', published_at: Time.current)
      conversation2 = Conversation.create!(job: job2)

      message1 = user.sent_messages.create!(conversation: conversation, content: 'Message to first conversation')
      message2 = user.sent_messages.create!(conversation: conversation2, content: 'Message to second conversation')

      expect(user.sent_messages.count).to eq(2)
      expect(message1.conversation).to eq(conversation)
      expect(message2.conversation).to eq(conversation2)
    end
  end

  describe 'taxonomy associations' do
    let(:user) { User.create!(email: 'musician@example.com', password: 'password123') }
    let(:genre) { Genre.find_by(name: 'Rock') || Genre.create!(name: 'Rock') }
    let(:instrument) { Instrument.find_by(name: 'Guitar') || Instrument.create!(name: 'Guitar') }
    let(:skill) { Skill.find_by(name: 'Composition') || Skill.create!(name: 'Composition') }

    it 'has many genres through musician_genres' do
      user.genres << genre
      expect(user.genres).to include(genre)
    end

    it 'has many instruments through musician_instruments' do
      user.instruments << instrument
      expect(user.instruments).to include(instrument)
    end

    it 'has many skills through musician_skills' do
      user.skills << skill
      expect(user.skills).to include(skill)
    end

    it 'destroys join records when user is deleted' do
      user.genres << genre
      user.instruments << instrument
      user.skills << skill

      user.destroy

      expect(MusicianGenre.where(user_id: user.id)).to be_empty
      expect(MusicianInstrument.where(user_id: user.id)).to be_empty
      expect(MusicianSkill.where(user_id: user.id)).to be_empty
    end
  end
end