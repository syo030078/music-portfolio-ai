class MusicianProfile < ApplicationRecord
  belongs_to :user

  validates :hourly_rate_jpy, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :avg_rating, numericality: { in: 0.0..5.0 }
  validates :rating_count, numericality: { greater_than_or_equal_to: 0 }
  validates :portfolio_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :headline, length: { maximum: 100 }, allow_blank: true
end
