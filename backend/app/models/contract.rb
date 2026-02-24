class Contract < ApplicationRecord
  belongs_to :proposal, optional: true
  belongs_to :production_request, optional: true
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
  validates :proposal_id, uniqueness: { message: 'already has a contract' }, allow_nil: true
  validates :production_request_id, uniqueness: { message: 'already has a contract' }, allow_nil: true
  validate :exactly_one_source

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

  def origin
    proposal || production_request
  end

  private

  def exactly_one_source
    has_proposal = proposal_id.present?
    has_production_request = production_request_id.present?

    unless has_proposal ^ has_production_request
      errors.add(:base, 'Contract must have exactly one source: proposal or production_request')
    end
  end
end
