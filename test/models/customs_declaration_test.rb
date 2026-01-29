require 'test_helper'

class CustomsDeclarationTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
    @shipping_request = FactoryBot.create(:shipping_request, sender: @sender, departure_country: "FR", arrival_country: "US")
    @declaration = CustomsDeclaration.new(
      shipping_request: @shipping_request,
      declared_by: @sender,
      origin_country: "FR",
      destination_country: "US",
      total_declared_value_cents: 5000,
      currency: "EUR",
      purpose: "personal",
      item_descriptions: '[{"description": "Books", "quantity": 3, "value_cents": 3000}]',
      sender_attestation: true
    )
  end

  test "should be valid with valid attributes" do
    assert @declaration.valid?
  end

  test "should generate declaration number on create" do
    @declaration.save!
    assert @declaration.declaration_number.present?
    assert @declaration.declaration_number.start_with?("SMB-CD-")
  end

  test "should require origin_country" do
    @declaration.origin_country = nil
    assert_not @declaration.valid?
  end

  test "should require destination_country" do
    @declaration.destination_country = nil
    assert_not @declaration.valid?
  end

  test "should require total_declared_value_cents" do
    @declaration.total_declared_value_cents = nil
    assert_not @declaration.valid?
  end

  test "should require valid purpose" do
    @declaration.purpose = "invalid"
    assert_not @declaration.valid?
  end

  test "should accept all valid purposes" do
    %w[personal commercial gift sample repair return].each do |purpose|
      @declaration.purpose = purpose
      assert @declaration.valid?, "#{purpose} should be valid"
    end
  end

  test "exceeds_duty_free_threshold? for US" do
    @declaration.total_declared_value_cents = 90000  # 900€ > 800$ threshold
    assert @declaration.exceeds_duty_free_threshold?
  end

  test "does not exceed duty_free_threshold for small amounts" do
    @declaration.total_declared_value_cents = 5000  # 50€
    assert_not @declaration.exceeds_duty_free_threshold?
  end

  test "requires_commercial_invoice? for commercial purpose" do
    @declaration.purpose = "commercial"
    assert @declaration.requires_commercial_invoice?
  end

  test "requires_commercial_invoice? for high value" do
    @declaration.total_declared_value_cents = 250000
    assert @declaration.requires_commercial_invoice?
  end

  test "parsed_items returns parsed JSON" do
    items = @declaration.parsed_items
    assert_equal 1, items.length
    assert_equal "Books", items.first["description"]
  end

  test "parsed_items returns empty array for invalid JSON" do
    @declaration.item_descriptions = "not json"
    assert_equal [], @declaration.parsed_items
  end
end
