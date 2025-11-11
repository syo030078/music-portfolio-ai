class AddUuidToThreadsAndParticipants < ActiveRecord::Migration[7.0]
  def up
    tables = [:threads, :thread_participants]

    tables.each do |table|
      execute <<-SQL
        ALTER TABLE #{table} ADD COLUMN uuid UUID DEFAULT gen_random_uuid() NOT NULL;
        CREATE UNIQUE INDEX index_#{table}_on_uuid ON #{table}(uuid);
      SQL
    end
  end

  def down
    tables = [:threads, :thread_participants]

    tables.each do |table|
      remove_column table, :uuid
    end
  end
end
