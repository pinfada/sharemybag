class CreateComplianceChecklists < ActiveRecord::Migration[7.0]
  def change
    create_table :compliance_checklists do |t|
      t.references :shipping_request, null: false, foreign_key: true, index: { unique: true }
      t.references :completed_by, null: false, foreign_key: { to_table: :users }, index: true

      # Sender attestations
      t.boolean :no_prohibited_items, default: false
      t.boolean :no_dangerous_goods, default: false
      t.boolean :accurate_description, default: false
      t.boolean :accurate_weight, default: false
      t.boolean :proper_packaging, default: false
      t.boolean :customs_compliant, default: false
      t.boolean :accepts_liability, default: false
      t.boolean :accepts_inspection, default: false

      # Security checks
      t.boolean :identity_verified, default: false
      t.boolean :security_screening_passed, default: false
      t.boolean :sanctions_check_passed, default: false
      t.boolean :customs_declaration_filed, default: false

      # Airline compliance
      t.boolean :airline_policy_checked, default: false
      t.boolean :weight_within_limits, default: false
      t.boolean :dimensions_within_limits, default: false

      t.boolean :fully_compliant, default: false
      t.datetime :completed_at
      t.string :completed_ip
      t.string :user_agent
      t.text :digital_signature # base64 encoded signature
      t.jsonb :metadata, default: {}
      t.timestamps
    end
  end
end
