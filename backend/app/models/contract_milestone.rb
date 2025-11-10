class ContractMilestone < ApplicationRecord
  belongs_to :contract

  enum status: {
    open: 'open',
    submitted: 'submitted',
    approved: 'approved',
    rejected: 'rejected',
    paid: 'paid'
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :amount_jpy, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :open, -> { where(status: 'open') }
  scope :submitted, -> { where(status: 'submitted') }
  scope :approved, -> { where(status: 'approved') }
  scope :paid, -> { where(status: 'paid') }
end
