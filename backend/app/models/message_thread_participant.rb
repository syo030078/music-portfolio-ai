class MessageThreadParticipant < ApplicationRecord
  self.table_name = 'thread_participants'

  belongs_to :thread, class_name: 'MessageThread', foreign_key: 'thread_id'
  belongs_to :user

  validates :thread_id, uniqueness: { scope: :user_id }
end
