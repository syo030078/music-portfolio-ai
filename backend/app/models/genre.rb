class Genre < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :musician_genres, dependent: :destroy
  has_many :users, through: :musician_genres
end
