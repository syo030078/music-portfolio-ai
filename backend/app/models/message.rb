class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :body, presence: true, length: { minimum: 1, maximum: 1000 }

  # UUID対応
  def to_param
    uuid
  end

  # 送信後に送信者を既読にする
  after_create :mark_sender_as_read

  private

  def mark_sender_as_read
    participant = conversation.conversation_participants.find_by(user: sender)
    participant&.mark_as_read!
  end
end
