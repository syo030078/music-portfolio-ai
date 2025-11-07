class ExpandJobsTable < ActiveRecord::Migration[7.0]
  def change
    # Add new columns
    add_column :jobs, :title, :string unless column_exists?(:jobs, :title)
    add_column :jobs, :budget_min_jpy, :integer unless column_exists?(:jobs, :budget_min_jpy)
    add_column :jobs, :budget_max_jpy, :integer unless column_exists?(:jobs, :budget_max_jpy)
    add_column :jobs, :delivery_due_on, :date unless column_exists?(:jobs, :delivery_due_on)
    add_column :jobs, :is_remote, :boolean, default: true unless column_exists?(:jobs, :is_remote)
    add_column :jobs, :location_note, :text unless column_exists?(:jobs, :location_note)
    add_column :jobs, :published_at, :datetime unless column_exists?(:jobs, :published_at)

    # Make track_id optional
    change_column_null :jobs, :track_id, true

    # Rename columns
    rename_column :jobs, :budget, :budget_jpy unless column_exists?(:jobs, :budget_jpy)
    rename_column :jobs, :user_id, :client_id unless column_exists?(:jobs, :client_id)

    # Set default value for status
    change_column_default :jobs, :status, from: nil, to: 'draft'

    # Add indexes
    add_index :jobs, :status unless index_exists?(:jobs, :status)
    add_index :jobs, :published_at unless index_exists?(:jobs, :published_at)

    # Update existing records
    reversible do |dir|
      dir.up do
        Job.where(title: nil).update_all(title: 'Untitled Job')
      end
    end
  end
end
