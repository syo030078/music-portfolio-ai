class AddProfileFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :display_name, :string unless column_exists?(:users, :display_name)
    add_column :users, :timezone, :string, default: 'UTC' unless column_exists?(:users, :timezone)
    add_column :users, :is_musician, :boolean, default: false unless column_exists?(:users, :is_musician)
    add_column :users, :is_client, :boolean, default: false unless column_exists?(:users, :is_client)
    add_column :users, :deleted_at, :datetime unless column_exists?(:users, :deleted_at)

    add_index :users, :deleted_at unless index_exists?(:users, :deleted_at)
  end
end
