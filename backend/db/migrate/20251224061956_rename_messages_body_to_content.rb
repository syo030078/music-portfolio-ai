class RenameMessagesBodyToContent < ActiveRecord::Migration[7.0]
  def change
    rename_column :messages, :body, :content
  end
end
