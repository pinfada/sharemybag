class AddComplianceFieldsToShippingRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :shipping_requests, :prohibited_items_acknowledged, :boolean, default: false
    add_column :shipping_requests, :content_declaration_verified, :boolean, default: false
    add_column :shipping_requests, :declared_value_cents, :decimal, precision: 10
    add_column :shipping_requests, :declared_contents, :jsonb, default: []
    add_column :shipping_requests, :contains_dangerous_goods, :boolean, default: false
    add_column :shipping_requests, :insurance_required, :boolean, default: false
    add_column :shipping_requests, :insurance_value_cents, :decimal, precision: 10
    add_column :shipping_requests, :compliance_status, :string, default: "pending"
    add_column :shipping_requests, :compliance_checked_at, :datetime
    add_column :shipping_requests, :airline_restrictions_checked, :boolean, default: false
    add_index :shipping_requests, :compliance_status
  end
end
