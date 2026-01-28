class CreateAirports < ActiveRecord::Migration[5.0]
  def change
    create_table :airports do |t|
      t.string :code
      t.string :location

      t.timestamps null: false
    end
  end
end
