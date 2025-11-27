class Conversation < ApplicationRecord
  belongs_to :job, optional: true
  belongs_to :contract, optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  # job_idとcontract_idのいずれか一方のみ必須
  validates :job_id, presence: true, if: -> { contract_id.blank? }
  validates :contract_id, presence: true, if: -> { job_id.blank? }
  validate :only_one_parent

  # UUID対応
  def to_param
    id.to_s
  end

  def self.find_by_uuid(uuid)
    find_by(id: uuid)
  end

  # 参加者チェック
  def participant?(user)
    participants.exists?(id: user.id)
  end

  # 未読メッセージ数取得
  def unread_count_for(user)
    participant = conversation_participants.find_by(user: user)
    return 0 unless participant

    messages.where('created_at > ?', participant.last_read_at || Time.at(0)).count
  end

  # 親リソース取得
  def parent
    job || contract
  end

  private

  def only_one_parent
    if job_id.present? && contract_id.present?
      errors.add(:base, 'Cannot belong to both job and contract')
    end
  end
end
