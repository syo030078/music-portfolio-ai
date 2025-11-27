class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.references :contract, null: false, foreign_key: true, index: false
      t.references :milestone, null: true, foreign_key: { to_table: :contract_milestones, on_delete: :nullify }, index: false
      t.integer :amount_jpy, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: 'authorized'
      t.string :provider
      t.string :provider_ref
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      t.timestamps
    end

    add_index :transactions, :uuid, unique: true
    add_index :transactions, :contract_id
    add_index :transactions, :milestone_id
    add_index :transactions, :kind
    add_index :transactions, :status
    add_check_constraint :transactions, 'amount_jpy > 0', name: 'transactions_amount_positive'
  end
end
