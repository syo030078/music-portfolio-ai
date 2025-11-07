class MusicianGenre < ApplicationRecord
  belongs_to :user
  belongs_to :genre

  validates :user_id, uniqueness: { scope: :genre_id }
end
