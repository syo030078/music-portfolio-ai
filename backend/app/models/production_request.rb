class ProductionRequest < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :musician, class_name: 'User', foreign_key: 'musician_id'
  has_one :contract, dependent: :restrict_with_error

  enum status: {
    pending: 'pending',
    accepted: 'accepted',
    rejected: 'rejected',
    withdrawn: 'withdrawn'
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :budget_jpy, presence: true, numericality: { greater_than: 0 }
  validates :delivery_days, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :status, presence: true
  validate :client_must_be_client_role
  validate :musician_must_be_musician_role
  validate :cannot_request_self

  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :for_musician, ->(musician_id) { where(musician_id: musician_id) }

  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end

  private

  def client_must_be_client_role
    return unless client

    errors.add(:client, 'must have client role') unless client.is_client?
  end

  def musician_must_be_musician_role
    return unless musician

    errors.add(:musician, 'must have musician role') unless musician.is_musician?
  end

  def cannot_request_self
    return unless client_id && musician_id

    errors.add(:musician, 'cannot request yourself') if client_id == musician_id
  end
end
