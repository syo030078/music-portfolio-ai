class ThreadParticipant < ApplicationRecord
  belongs_to :thread, class_name: 'MessageThread', foreign_key: 'thread_id'
  belongs_to :user

  validates :thread_id, uniqueness: { scope: :user_id }
end
