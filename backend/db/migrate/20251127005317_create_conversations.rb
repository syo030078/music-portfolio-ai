class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations, id: :uuid do |t|
      t.references :job, foreign_key: true, type: :bigint, null: true
      t.references :contract, foreign_key: true, type: :bigint, null: true
      t.timestamps
    end

    # CHECK制約: job_idとcontract_idのいずれか一方のみ必須（XOR）
    add_check_constraint :conversations,
      "(job_id IS NOT NULL AND contract_id IS NULL) OR (job_id IS NULL AND contract_id IS NOT NULL)",
      name: 'conversations_job_or_contract'
  end
end
