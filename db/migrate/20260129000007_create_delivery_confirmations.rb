class CreateDeliveryConfirmations < ActiveRecord::Migration[7.0]
  def change
    create_table :delivery_confirmations do |t|
      t.integer :shipment_tracking_id, null: false
      t.integer :sender_id, null: false
      t.integer :traveler_id, null: false
      t.string :otp_digest, null: false
      t.datetime :otp_generated_at, null: false
      t.datetime :otp_expires_at, null: false
      t.datetime :otp_verified_at
      t.integer :attempts_count, default: 0
      t.integer :max_attempts, default: 3
      t.boolean :blocked, default: false
      t.datetime :blocked_at
      t.string :delivery_photo_url
      t.decimal :delivery_latitude, precision: 10, scale: 7
      t.decimal :delivery_longitude, precision: 10, scale: 7
      t.string :delivery_address
      t.boolean :sms_sent, default: false
      t.datetime :sms_sent_at
      t.string :sms_provider
      t.string :sms_message_sid
      t.boolean :email_sent, default: false
      t.datetime :email_sent_at
      t.string :notification_channel
      t.string :confirmed_by_ip
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :delivery_confirmations, :shipment_tracking_id, unique: true
    add_index :delivery_confirmations, :sender_id
    add_index :delivery_confirmations, :traveler_id
    add_foreign_key :delivery_confirmations, :shipment_trackings, column: :shipment_tracking_id
    add_foreign_key :delivery_confirmations, :users, column: :sender_id
    add_foreign_key :delivery_confirmations, :users, column: :traveler_id
  end
end
