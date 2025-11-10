class AddUuidToAllTables < ActiveRecord::Migration[7.0]
  def change
    # Add uuid column to all tables with bigint primary keys
    add_column :users, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :users, :uuid, unique: true

    add_column :tracks, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :tracks, :uuid, unique: true

    add_column :jobs, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :jobs, :uuid, unique: true

    add_column :messages, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :messages, :uuid, unique: true

    add_column :musician_profiles, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :musician_profiles, :uuid, unique: true

    add_column :client_profiles, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :client_profiles, :uuid, unique: true

    add_column :genres, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :genres, :uuid, unique: true

    add_column :instruments, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :instruments, :uuid, unique: true

    add_column :skills, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :skills, :uuid, unique: true

    add_column :musician_genres, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :musician_genres, :uuid, unique: true

    add_column :musician_instruments, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :musician_instruments, :uuid, unique: true

    add_column :musician_skills, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :musician_skills, :uuid, unique: true

    add_column :job_requirements, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :job_requirements, :uuid, unique: true

    add_column :proposals, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :proposals, :uuid, unique: true

    add_column :contracts, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :contracts, :uuid, unique: true

    add_column :contract_milestones, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :contract_milestones, :uuid, unique: true
  end
end
