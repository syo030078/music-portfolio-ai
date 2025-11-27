class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :tracks, dependent: :destroy
  has_many :jobs, foreign_key: 'client_id', dependent: :destroy
  has_one :musician_profile, dependent: :destroy
  has_one :client_profile, dependent: :destroy
  has_many :proposals, foreign_key: 'musician_id', dependent: :destroy
  has_many :client_contracts, class_name: 'Contract', foreign_key: 'client_id', dependent: :destroy
  has_many :musician_contracts, class_name: 'Contract', foreign_key: 'musician_id', dependent: :destroy

  # Conversation associations
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id, dependent: :destroy

  # Taxonomy associations
  has_many :musician_genres, dependent: :destroy
  has_many :genres, through: :musician_genres

  has_many :musician_instruments, dependent: :destroy
  has_many :instruments, through: :musician_instruments

  has_many :musician_skills, dependent: :destroy
  has_many :skills, through: :musician_skills

  # Validations
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_nil: true
  validates :display_name, length: { maximum: 50 }, allow_blank: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :musicians, -> { where(is_musician: true) }
  scope :clients, -> { where(is_client: true) }

  # UUID support
  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end

  # Soft delete
  def soft_delete
    update(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end
end


