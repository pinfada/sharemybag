class CreateReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :reviews do |t|
      t.references :reviewer, foreign_key: { to_table: :users }, null: false
      t.references :reviewee, foreign_key: { to_table: :users }, null: false
      t.references :shipping_request, foreign_key: true, null: false
      t.integer :rating, null: false
      t.text :comment
      t.string :role, null: false

      t.timestamps
    end

    add_index :reviews, [:reviewer_id, :shipping_request_id], unique: true
  end
end
