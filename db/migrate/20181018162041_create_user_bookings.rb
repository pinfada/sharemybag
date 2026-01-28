class CreateUserBookings < ActiveRecord::Migration[5.0]
  def change
    create_table :user_bookings do |t|
      t.references :booking, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.references :bagage, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
