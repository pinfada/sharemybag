class AddOtpFieldsToShipmentTrackings < ActiveRecord::Migration[7.0]
  def change
    add_column :shipment_trackings, :otp_delivery_code, :string
    add_column :shipment_trackings, :otp_required, :boolean, default: false
    add_column :shipment_trackings, :delivery_confirmed_via_otp, :boolean, default: false
  end
end
