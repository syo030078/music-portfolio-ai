class Message < ApplicationRecord
  belongs_to :commission
  belongs_to :user

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
end
