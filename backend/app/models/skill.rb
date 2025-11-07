class Skill < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :musician_skills, dependent: :destroy
  has_many :users, through: :musician_skills
end
