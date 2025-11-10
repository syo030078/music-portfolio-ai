class Proposal < ApplicationRecord
  belongs_to :job
  belongs_to :musician, class_name: 'User', foreign_key: 'musician_id'
  has_one :contract, dependent: :destroy

  enum status: {
    submitted: 'submitted',
    shortlisted: 'shortlisted',
    accepted: 'accepted',
    rejected: 'rejected',
    withdrawn: 'withdrawn'
  }

  validates :cover_message, length: { maximum: 2000 }, allow_blank: true
  validates :quote_total_jpy, presence: true, numericality: { greater_than: 0 }
  validates :delivery_days, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :status, presence: true
  validate :musician_cannot_be_job_owner
  validate :job_must_be_published
  validates :musician_id, uniqueness: { scope: :job_id, message: 'has already submitted a proposal for this job' }

  scope :for_job, ->(job_id) { where(job_id: job_id) }
  scope :by_musician, ->(musician_id) { where(musician_id: musician_id) }
  scope :submitted, -> { where(status: 'submitted') }
  scope :shortlisted, -> { where(status: 'shortlisted') }
  scope :accepted, -> { where(status: 'accepted') }

  private

  def musician_cannot_be_job_owner
    return unless job && musician_id

    if job.client_id == musician_id
      errors.add(:musician_id, 'cannot submit proposal to own job')
    end
  end

  def job_must_be_published
    return unless job

    unless job.published?
      errors.add(:job, 'must be published to accept proposals')
    end
  end
end
