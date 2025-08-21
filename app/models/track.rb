class Track < ApplicationRecord
  belongs_to :user

  validates :yt_url, presence: true
end
