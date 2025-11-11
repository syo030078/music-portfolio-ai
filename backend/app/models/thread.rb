class Thread < ApplicationRecord
  belongs_to :job, optional: true
  belongs_to :contract, optional: true
  has_many :participants, class_name: 'ThreadParticipant', dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, dependent: :destroy

  validate :job_or_contract_present

  # UUID support
  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end

  private

  def job_or_contract_present
    if job_id.nil? && contract_id.nil?
      errors.add(:base, 'must have either job or contract')
    elsif job_id.present? && contract_id.present?
      errors.add(:base, 'cannot have both job and contract')
    end
  end
end
