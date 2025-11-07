require 'rails_helper'

RSpec.describe Instrument, type: :model do
  describe 'validations' do
    subject { Instrument.new(name: 'Flute') }

    it 'is valid with a name' do
      expect(subject).to be_valid
    end

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'validates uniqueness of name' do
      Instrument.find_or_create_by!(name: 'Piano')
      duplicate = Instrument.new(name: 'Piano')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many musician_instruments' do
      association = described_class.reflect_on_association(:musician_instruments)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many users through musician_instruments' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:musician_instruments)
    end
  end
end
