class Job < ApplicationRecord
  belongs_to :user
  belongs_to :track
  has_many :messages, dependent: :destroy

  enum status: {
    pending: 'pending',
    accepted: 'accepted',
    done: 'done'
  }

  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
end
