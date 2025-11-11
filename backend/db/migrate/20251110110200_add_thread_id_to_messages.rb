class AddThreadIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :messages, :thread, foreign_key: true, type: :bigint
  end
end
