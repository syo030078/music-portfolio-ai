require 'rails_helper'

RSpec.describe ClientProfile, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }

    it 'is valid with valid attributes' do
      profile = ClientProfile.new(user: user)
      expect(profile).to be_valid
    end

    describe 'organization' do
      it 'allows nil' do
        profile = ClientProfile.new(user: user, organization: nil)
        expect(profile).to be_valid
      end

      it 'allows strings up to 255 characters' do
        profile = ClientProfile.new(user: user, organization: 'a' * 255)
        expect(profile).to be_valid
      end

      it 'does not allow strings longer than 255 characters' do
        profile = ClientProfile.new(user: user, organization: 'a' * 256)
        expect(profile).not_to be_valid
        expect(profile.errors[:organization]).to include('is too long (maximum is 255 characters)')
      end
    end
  end

  describe 'default values' do
    let(:user) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
    let(:profile) { ClientProfile.create!(user: user) }

    it 'sets verified to false' do
      expect(profile.verified).to be false
    end
  end
end
