class AddProductionRequestToContracts < ActiveRecord::Migration[7.0]
  def up
    add_reference :contracts, :production_request,
                  foreign_key: true,
                  type: :bigint,
                  null: true

    change_column_null :contracts, :proposal_id, true

    remove_index :contracts, :proposal_id if index_exists?(:contracts, :proposal_id)

    add_index :contracts, :proposal_id,
              unique: true,
              where: "proposal_id IS NOT NULL",
              name: "index_contracts_on_proposal_id_unique"

    add_index :contracts, :production_request_id,
              unique: true,
              where: "production_request_id IS NOT NULL",
              name: "index_contracts_on_production_request_id_unique"

    add_check_constraint :contracts,
      "(proposal_id IS NOT NULL AND production_request_id IS NULL) OR " \
      "(proposal_id IS NULL AND production_request_id IS NOT NULL)",
      name: "contracts_proposal_or_production_request"
  end

  def down
    remove_check_constraint :contracts, name: "contracts_proposal_or_production_request"
    remove_index :contracts, name: "index_contracts_on_production_request_id_unique"
    remove_index :contracts, name: "index_contracts_on_proposal_id_unique"
    add_index :contracts, :proposal_id, unique: true
    change_column_null :contracts, :proposal_id, false
    remove_reference :contracts, :production_request
  end
end
