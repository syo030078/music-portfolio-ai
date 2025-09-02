class Track < ApplicationRecord
  belongs_to :user

  before_validation :normalize_yt_url

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 1000 }
  validates :yt_url, presence: true,
    format: { with: /\Ahttps?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)/i }

  private
  def normalize_yt_url
    self.yt_url = yt_url&.strip
    self.title  = title&.strip
  end
end
