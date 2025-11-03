class RenameCommissionsToJobs < ActiveRecord::Migration[7.0]
  def change
    # Rename commissions table to jobs
    rename_table :commissions, :jobs

    # Rename commission_id to job_id in messages table
    rename_column :messages, :commission_id, :job_id
  end
end
