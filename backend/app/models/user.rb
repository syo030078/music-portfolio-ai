class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :tracks, dependent: :destroy
  has_many :jobs, dependent: :destroy
  has_many :messages, dependent: :destroy

  # Validations
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_nil: true
  validates :display_name, length: { maximum: 50 }, allow_blank: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :musicians, -> { where(is_musician: true) }
  scope :clients, -> { where(is_client: true) }

  # Soft delete
  def soft_delete
    update(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end
end


