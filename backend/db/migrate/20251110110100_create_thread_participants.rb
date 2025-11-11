class CreateThreadParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :thread_participants do |t|
      t.references :thread, null: false, foreign_key: true, type: :bigint
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.timestamps
    end

    add_index :thread_participants, [:thread_id, :user_id], unique: true
  end
end
