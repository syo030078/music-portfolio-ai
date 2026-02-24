class CreateProductionRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :production_requests do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.references :musician, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.string :title, null: false
      t.text :description, null: false
      t.integer :budget_jpy, null: false
      t.integer :delivery_days, null: false
      t.string :status, null: false, default: 'pending'
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }

      t.timestamps
    end

    add_index :production_requests, :uuid, unique: true
    add_index :production_requests, :status
    add_index :production_requests, [:client_id, :musician_id]
  end
end
