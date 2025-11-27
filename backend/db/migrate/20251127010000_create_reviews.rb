class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.references :contract, null: false, foreign_key: true, index: false
      t.references :reviewer, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewee, null: false, foreign_key: { to_table: :users }, index: false
      t.integer :rating, null: false
      t.text :comment
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      t.timestamps
    end

    add_index :reviews, :uuid, unique: true
    add_index :reviews, :rating
    add_index :reviews, :reviewer_id
    add_index :reviews, :reviewee_id
    add_index :reviews, :contract_id, unique: true
    add_check_constraint :reviews, 'rating >= 1 AND rating <= 5', name: 'reviews_rating_range'
  end
end
