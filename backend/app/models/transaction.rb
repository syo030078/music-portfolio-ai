class Transaction < ApplicationRecord
  belongs_to :contract
  belongs_to :milestone, class_name: 'ContractMilestone', optional: true

  enum kind: {
    escrow_deposit: 'escrow_deposit',
    milestone_payout: 'milestone_payout',
    refund: 'refund',
    platform_fee: 'platform_fee'
  }

  enum status: {
    authorized: 'authorized',
    captured: 'captured',
    paid_out: 'paid_out',
    failed: 'failed',
    refunded: 'refunded'
  }

  validates :amount_jpy, presence: true, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :status, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :for_milestone, ->(milestone_id) { where(milestone_id: milestone_id) }

  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end
end
