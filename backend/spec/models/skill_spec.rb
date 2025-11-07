require 'rails_helper'

RSpec.describe Skill, type: :model do
  describe 'validations' do
    subject { Skill.new(name: 'Editing') }

    it 'is valid with a name' do
      expect(subject).to be_valid
    end

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'validates uniqueness of name' do
      Skill.find_or_create_by!(name: 'Composition')
      duplicate = Skill.new(name: 'Composition')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many musician_skills' do
      association = described_class.reflect_on_association(:musician_skills)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many users through musician_skills' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:musician_skills)
    end
  end
end
