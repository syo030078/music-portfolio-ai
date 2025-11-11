class ThreadParticipant < ApplicationRecord
  belongs_to :thread
  belongs_to :user

  validates :thread_id, uniqueness: { scope: :user_id }
end
