class CreateClientProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :client_profiles do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint, index: { unique: true }
      t.string :organization
      t.boolean :verified, default: false

      t.timestamps
    end
  end
end
