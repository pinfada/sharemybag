class AddCustomsValueAndOpenInspection < ActiveRecord::Migration[7.0]
  def change
    add_column :shipping_requests, :declared_value_cents, :integer unless column_exists?(:shipping_requests, :declared_value_cents)
    add_column :shipment_trackings, :open_inspection_confirmed_at, :datetime unless column_exists?(:shipment_trackings, :open_inspection_confirmed_at)
  end
end
