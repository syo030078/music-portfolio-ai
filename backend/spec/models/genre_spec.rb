require 'rails_helper'

RSpec.describe Genre, type: :model do
  describe 'validations' do
    subject { Genre.new(name: 'Alternative') }

    it 'is valid with a name' do
      expect(subject).to be_valid
    end

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'validates uniqueness of name' do
      Genre.find_or_create_by!(name: 'Rock')
      duplicate = Genre.new(name: 'Rock')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many musician_genres' do
      association = described_class.reflect_on_association(:musician_genres)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many users through musician_genres' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:musician_genres)
    end
  end
end
