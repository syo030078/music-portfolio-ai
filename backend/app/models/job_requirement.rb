class JobRequirement < ApplicationRecord
  belongs_to :job

  enum kind: {
    genre: 'genre',
    instrument: 'instrument',
    skill: 'skill'
  }

  validates :kind, presence: true
  validates :ref_id, presence: true
  validate :ref_id_exists

  # ヘルパーメソッド
  def reference_object
    case kind
    when 'genre'
      Genre.find_by(id: ref_id)
    when 'instrument'
      Instrument.find_by(id: ref_id)
    when 'skill'
      Skill.find_by(id: ref_id)
    end
  end

  def reference_name
    reference_object&.name
  end

  private

  def ref_id_exists
    return if reference_object.present?
    errors.add(:ref_id, "#{kind} with id #{ref_id} does not exist")
  end
end
