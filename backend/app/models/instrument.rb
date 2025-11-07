class Instrument < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :musician_instruments, dependent: :destroy
  has_many :users, through: :musician_instruments
end
