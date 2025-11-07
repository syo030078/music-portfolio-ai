class Job < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :track, optional: true
  has_many :messages, dependent: :destroy

  enum status: {
    draft: 'draft',
    published: 'published',
    in_review: 'in_review',
    contracted: 'contracted',
    completed: 'completed',
    closed: 'closed'
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :budget_jpy, numericality: { greater_than: 0 }, allow_nil: true
  validates :budget_min_jpy, numericality: { greater_than: 0 }, allow_nil: true
  validates :budget_max_jpy, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, presence: true
  validate :budget_max_greater_than_min

  scope :published, -> { where(status: 'published').where.not(published_at: nil) }

  private

  def budget_max_greater_than_min
    return unless budget_min_jpy && budget_max_jpy
    errors.add(:budget_max_jpy, 'must be greater than or equal to minimum') if budget_max_jpy < budget_min_jpy
  end
end
