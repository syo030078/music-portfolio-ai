require 'rails_helper'

RSpec.describe MusicianGenre, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:genre) { Genre.find_by(name: 'Rock') || Genre.create!(name: 'Rock') }

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to genre' do
      association = described_class.reflect_on_association(:genre)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to genre_id' do
      MusicianGenre.create!(user: user, genre: genre)
      duplicate = MusicianGenre.new(user: user, genre: genre)
      expect(duplicate).not_to be_valid
    end

    it 'allows same genre for different users' do
      user2 = User.create!(email: 'test2@example.com', password: 'password123')
      MusicianGenre.create!(user: user, genre: genre)
      second = MusicianGenre.new(user: user2, genre: genre)
      expect(second).to be_valid
    end
  end
end
