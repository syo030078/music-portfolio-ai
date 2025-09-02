class CreateTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :tracks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :yt_url
      t.float :bpm
      t.string :key
      t.string :genre
      t.text :ai_text

      t.timestamps
    end
  end
end
