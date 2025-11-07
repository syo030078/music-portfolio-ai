class CreateMusicianTaxonomyJoinTables < ActiveRecord::Migration[7.0]
  def change
    create_table :musician_genres do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :genre, null: false, foreign_key: true, type: :bigint
    end
    add_index :musician_genres, [:user_id, :genre_id], unique: true

    create_table :musician_instruments do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :instrument, null: false, foreign_key: true, type: :bigint
    end
    add_index :musician_instruments, [:user_id, :instrument_id], unique: true

    create_table :musician_skills do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :skill, null: false, foreign_key: true, type: :bigint
    end
    add_index :musician_skills, [:user_id, :skill_id], unique: true
  end
end
