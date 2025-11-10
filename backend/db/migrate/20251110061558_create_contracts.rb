class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :contracts do |t|
      t.references :proposal, null: false, foreign_key: true, type: :bigint
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.references :musician, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.string :status, null: false, default: 'active'
      t.integer :escrow_total_jpy, null: false

      t.timestamps
    end

    add_index :contracts, :proposal_id, unique: true
    add_index :contracts, :status
  end
end
