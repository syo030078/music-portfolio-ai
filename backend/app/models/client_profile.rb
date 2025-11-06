class ClientProfile < ApplicationRecord
  belongs_to :user

  validates :organization, length: { maximum: 255 }
end
