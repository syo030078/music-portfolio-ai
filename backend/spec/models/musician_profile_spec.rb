require 'rails_helper'

RSpec.describe MusicianProfile, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }

    it 'is valid with valid attributes' do
      profile = MusicianProfile.new(user: user)
      expect(profile).to be_valid
    end

    describe 'hourly_rate_jpy' do
      it 'allows nil' do
        profile = MusicianProfile.new(user: user, hourly_rate_jpy: nil)
        expect(profile).to be_valid
      end

      it 'allows positive values' do
        profile = MusicianProfile.new(user: user, hourly_rate_jpy: 5000)
        expect(profile).to be_valid
      end

      it 'allows zero' do
        profile = MusicianProfile.new(user: user, hourly_rate_jpy: 0)
        expect(profile).to be_valid
      end

      it 'does not allow negative values' do
        profile = MusicianProfile.new(user: user, hourly_rate_jpy: -100)
        expect(profile).not_to be_valid
        expect(profile.errors[:hourly_rate_jpy]).to include('must be greater than or equal to 0')
      end
    end

    describe 'avg_rating' do
      it 'allows values between 0.0 and 5.0' do
        profile = MusicianProfile.new(user: user, avg_rating: 3.5)
        expect(profile).to be_valid
      end

      it 'does not allow values less than 0.0' do
        profile = MusicianProfile.new(user: user, avg_rating: -0.1)
        expect(profile).not_to be_valid
      end

      it 'does not allow values greater than 5.0' do
        profile = MusicianProfile.new(user: user, avg_rating: 5.1)
        expect(profile).not_to be_valid
      end
    end

    describe 'rating_count' do
      it 'allows zero' do
        profile = MusicianProfile.new(user: user, rating_count: 0)
        expect(profile).to be_valid
      end

      it 'allows positive values' do
        profile = MusicianProfile.new(user: user, rating_count: 10)
        expect(profile).to be_valid
      end

      it 'does not allow negative values' do
        profile = MusicianProfile.new(user: user, rating_count: -1)
        expect(profile).not_to be_valid
      end
    end

    describe 'portfolio_url' do
      it 'allows valid HTTP URLs' do
        profile = MusicianProfile.new(user: user, portfolio_url: 'http://example.com')
        expect(profile).to be_valid
      end

      it 'allows valid HTTPS URLs' do
        profile = MusicianProfile.new(user: user, portfolio_url: 'https://example.com')
        expect(profile).to be_valid
      end

      it 'allows blank' do
        profile = MusicianProfile.new(user: user, portfolio_url: '')
        expect(profile).to be_valid
      end

      it 'does not allow invalid URLs' do
        profile = MusicianProfile.new(user: user, portfolio_url: 'invalid-url')
        expect(profile).not_to be_valid
      end
    end

    describe 'headline' do
      it 'allows blank' do
        profile = MusicianProfile.new(user: user, headline: '')
        expect(profile).to be_valid
      end

      it 'allows strings up to 100 characters' do
        profile = MusicianProfile.new(user: user, headline: 'a' * 100)
        expect(profile).to be_valid
      end

      it 'does not allow strings longer than 100 characters' do
        profile = MusicianProfile.new(user: user, headline: 'a' * 101)
        expect(profile).not_to be_valid
        expect(profile.errors[:headline]).to include('is too long (maximum is 100 characters)')
      end
    end
  end

  describe 'default values' do
    let(:user) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
    let(:profile) { MusicianProfile.create!(user: user) }

    it 'sets remote_ok to false' do
      expect(profile.remote_ok).to be false
    end

    it 'sets onsite_ok to false' do
      expect(profile.onsite_ok).to be false
    end

    it 'sets avg_rating to 0.0' do
      expect(profile.avg_rating).to eq(0.0)
    end

    it 'sets rating_count to 0' do
      expect(profile.rating_count).to eq(0)
    end
  end
end
