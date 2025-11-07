require 'rails_helper'

RSpec.describe MusicianSkill, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:skill) { Skill.find_by(name: 'Composition') || Skill.create!(name: 'Composition') }

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to skill' do
      association = described_class.reflect_on_association(:skill)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to skill_id' do
      MusicianSkill.create!(user: user, skill: skill)
      duplicate = MusicianSkill.new(user: user, skill: skill)
      expect(duplicate).not_to be_valid
    end

    it 'allows same skill for different users' do
      user2 = User.create!(email: 'test2@example.com', password: 'password123')
      MusicianSkill.create!(user: user, skill: skill)
      second = MusicianSkill.new(user: user2, skill: skill)
      expect(second).to be_valid
    end
  end
end
