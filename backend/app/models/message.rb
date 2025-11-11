class Message < ApplicationRecord
  belongs_to :thread, class_name: 'MessageThread', foreign_key: 'thread_id', optional: true
  belongs_to :job, optional: true
  belongs_to :sender, class_name: 'User', foreign_key: 'user_id'

  # 後方互換性のためのエイリアス
  alias_method :user, :sender
  alias_method :user=, :sender=

  validates :content, presence: true, length: { minimum: 1, maximum: 5000 }
  validate :thread_or_job_present

  private

  def thread_or_job_present
    if thread_id.nil? && job_id.nil?
      errors.add(:base, 'must have either thread or job')
    end
  end
end
