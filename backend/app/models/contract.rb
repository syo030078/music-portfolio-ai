class Contract < ApplicationRecord
  belongs_to :proposal
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :musician, class_name: 'User', foreign_key: 'musician_id'
  has_many :contract_milestones, dependent: :destroy
  has_many :conversations, dependent: :destroy

  enum status: {
    active: 'active',
    in_progress: 'in_progress',
    delivered: 'delivered',
    completed: 'completed',
    canceled: 'canceled'
  }

  validates :escrow_total_jpy, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :proposal_id, uniqueness: { message: 'already has a contract' }

  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :for_musician, ->(musician_id) { where(musician_id: musician_id) }
  scope :active, -> { where(status: 'active') }
  scope :in_progress, -> { where(status: 'in_progress') }

  # UUID support
  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end
end
