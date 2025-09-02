class AddIndexesToTracks < ActiveRecord::Migration[7.0]
  def change
    add_index :tracks, [:user_id, :created_at]
    add_index :tracks, [:user_id, :yt_url], unique: true
  end
end
