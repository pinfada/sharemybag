class CreateStripeWebhookEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_webhook_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.boolean :processed, default: false
      t.text :processing_errors
      t.datetime :processed_at

      t.timestamps
    end

    add_index :stripe_webhook_events, :stripe_event_id, unique: true
    add_index :stripe_webhook_events, :event_type
  end
end
