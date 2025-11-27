class CreateConversationParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_participants, id: :uuid do |t|
      t.references :conversation, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :conversation_participants, [:conversation_id, :user_id],
      unique: true, name: 'index_conversation_participants_on_conversation_and_user'
  end
end
