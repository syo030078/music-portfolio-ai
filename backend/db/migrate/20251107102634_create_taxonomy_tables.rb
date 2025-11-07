class CreateTaxonomyTables < ActiveRecord::Migration[7.0]
  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :genres, :name, unique: true

    create_table :instruments do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :instruments, :name, unique: true

    create_table :skills do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :skills, :name, unique: true
  end
end
