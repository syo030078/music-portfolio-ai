class AddUuidToAllTables < ActiveRecord::Migration[7.0]
  def up
    # Add uuid column to all tables with bigint primary keys using raw SQL
    tables = [
      :users, :tracks, :jobs, :messages,
      :musician_profiles, :client_profiles,
      :genres, :instruments, :skills,
      :musician_genres, :musician_instruments, :musician_skills,
      :job_requirements,
      :proposals, :contracts, :contract_milestones
    ]

    tables.each do |table|
      execute <<-SQL
        ALTER TABLE #{table} ADD COLUMN uuid UUID DEFAULT gen_random_uuid() NOT NULL;
        CREATE UNIQUE INDEX index_#{table}_on_uuid ON #{table}(uuid);
      SQL
    end
  end

  def down
    tables = [
      :users, :tracks, :jobs, :messages,
      :musician_profiles, :client_profiles,
      :genres, :instruments, :skills,
      :musician_genres, :musician_instruments, :musician_skills,
      :job_requirements,
      :proposals, :contracts, :contract_milestones
    ]

    tables.each do |table|
      remove_column table, :uuid
    end
  end
end
