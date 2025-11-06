class CreateMusicianProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :musician_profiles do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint, index: { unique: true }
      t.text :headline
      t.text :bio
      t.integer :hourly_rate_jpy
      t.boolean :remote_ok, default: false
      t.boolean :onsite_ok, default: false
      t.string :portfolio_url
      t.decimal :avg_rating, precision: 2, scale: 1, default: 0.0
      t.integer :rating_count, default: 0

      t.timestamps
    end
  end
end
