require 'rails_helper'

RSpec.describe MusicianInstrument, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:instrument) { Instrument.create!(name: 'Piano') }

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to instrument' do
      association = described_class.reflect_on_association(:instrument)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to instrument_id' do
      MusicianInstrument.create!(user: user, instrument: instrument)
      duplicate = MusicianInstrument.new(user: user, instrument: instrument)
      expect(duplicate).not_to be_valid
    end

    it 'allows same instrument for different users' do
      user2 = User.create!(email: 'test2@example.com', password: 'password123')
      MusicianInstrument.create!(user: user, instrument: instrument)
      second = MusicianInstrument.new(user: user2, instrument: instrument)
      expect(second).to be_valid
    end
  end
end
