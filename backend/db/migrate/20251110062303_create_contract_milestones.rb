class CreateContractMilestones < ActiveRecord::Migration[7.0]
  def change
    create_table :contract_milestones do |t|
      t.references :contract, null: false, foreign_key: true, type: :bigint
      t.string :title, null: false
      t.integer :amount_jpy, null: false
      t.date :due_on
      t.string :status, null: false, default: 'open'

      t.timestamps
    end

    add_index :contract_milestones, :status
  end
end
