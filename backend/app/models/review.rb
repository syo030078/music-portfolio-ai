class Review < ApplicationRecord
  belongs_to :contract
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewee, class_name: 'User'

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :contract_id, uniqueness: true
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validates :reviewer_id, presence: true
  validates :reviewee_id, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :for_user, ->(user_id) { where('reviewer_id = ? OR reviewee_id = ?', user_id, user_id) }

  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end
end
