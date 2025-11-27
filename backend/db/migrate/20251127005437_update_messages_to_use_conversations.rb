class UpdateMessagesToUseConversations < ActiveRecord::Migration[7.0]
  def change
    # 既存のjob_id参照を削除
    remove_reference :messages, :job, foreign_key: true, index: true

    # conversation_id追加（uuid型）
    add_reference :messages, :conversation, null: true, foreign_key: true, type: :uuid
    add_index :messages, [:conversation_id, :created_at]

    # カラム名変更（ER図に合わせる）
    rename_column :messages, :content, :body
    rename_column :messages, :user_id, :sender_id

    # Phase 6用のattachment_url追加
    add_column :messages, :attachment_url, :text

    # conversation_idをNOT NULLに変更（既存データがないため安全）
    change_column_null :messages, :conversation_id, false
  end
end
