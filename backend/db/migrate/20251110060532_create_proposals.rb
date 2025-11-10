class CreateProposals < ActiveRecord::Migration[7.0]
  def change
    create_table :proposals do |t|
      t.references :job, null: false, foreign_key: true, type: :bigint
      t.references :musician, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.text :cover_message
      t.integer :quote_total_jpy, null: false
      t.integer :delivery_days, null: false
      t.string :status, null: false, default: 'submitted'

      t.timestamps
    end

    add_index :proposals, [:job_id, :musician_id], unique: true
    add_index :proposals, :status
  end
end
