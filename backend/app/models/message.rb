class Message < ApplicationRecord
  belongs_to :job
  belongs_to :user

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
end
