class Commission < ApplicationRecord
  belongs_to :user
  belongs_to :track

  enum status: {
    pending: 'pending',
    accepted: 'accepted', 
    done: 'done'
  }

  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
end
