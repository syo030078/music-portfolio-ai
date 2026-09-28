class Track < ApplicationRecord
  belongs_to :user
  has_many :jobs, dependent: :destroy

  before_validation :normalize_yt_url

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 1000 }
  validates :yt_url,
    format: { with: /\Ahttps?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)/i },
    allow_blank: true

  # 検索フィルタ: 値が空なら絞り込まない（チェーン可能な all を返す）
  scope :by_user_uuid, ->(uuid) { uuid.present? ? joins(:user).where(users: { uuid: uuid }) : all }
  scope :by_genre, ->(genre) { genre.present? ? where(genre: genre) : all }
  scope :by_key, ->(key) { key.present? ? where(key: key) : all }
  scope :bpm_min, ->(bpm) { bpm.present? ? where('bpm >= ?', bpm.to_f) : all }
  scope :bpm_max, ->(bpm) { bpm.present? ? where('bpm <= ?', bpm.to_f) : all }

  private
  def normalize_yt_url
    self.yt_url = yt_url&.strip
    self.title  = title&.strip
  end
end
