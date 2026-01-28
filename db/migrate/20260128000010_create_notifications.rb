class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.references :user, foreign_key: true, null: false
      t.string :notifiable_type, null: false
      t.integer :notifiable_id, null: false
      t.string :action, null: false
      t.text :message
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
