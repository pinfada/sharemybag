require 'test_helper'

class ProhibitedItemsServiceTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
  end

  test "should detect explosives in description" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Contains fireworks for celebration")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert_not result[:passed]
    assert result[:blocked_items].any? { |i| i[:category] == "explosives" }
  end

  test "should detect weapons keywords" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Shipping a hunting rifle")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert_not result[:passed]
    assert result[:blocked_items].any? { |i| i[:category] == "weapons" }
  end

  test "should detect drug-related items" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Package of cannabis products")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert_not result[:passed]
    assert result[:blocked_items].any? { |i| i[:category] == "drugs" }
  end

  test "should pass for safe items" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Books and clothing")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert result[:passed]
    assert_empty result[:blocked_items]
  end

  test "should detect items in title" do
    request = FactoryBot.create(:shipping_request, sender: @sender, title: "Send ammunition", description: "Need to ship")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert_not result[:passed]
  end

  test "should detect radioactive materials" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Uranium sample for research")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert_not result[:passed]
    assert result[:blocked_items].any? { |i| i[:category] == "radioactive" }
  end

  test "should warn about items requiring declaration" do
    request = FactoryBot.create(:shipping_request, sender: @sender, description: "Shipping aerosol hairspray")
    service = ProhibitedItemsService.new(request)
    result = service.screen_contents!

    assert result[:warnings].any? || result[:requires_declaration].any?
  end

  test "universally_prohibited? returns true for explosives" do
    request = FactoryBot.create(:shipping_request, sender: @sender)
    service = ProhibitedItemsService.new(request)
    assert service.universally_prohibited?(:explosives)
    assert service.universally_prohibited?(:weapons)
    assert service.universally_prohibited?(:drugs)
    assert service.universally_prohibited?(:radioactive)
  end

  test "universally_prohibited? returns false for flammable_liquids" do
    request = FactoryBot.create(:shipping_request, sender: @sender)
    service = ProhibitedItemsService.new(request)
    assert_not service.universally_prohibited?(:flammable_liquids)
    assert_not service.universally_prohibited?(:gases)
  end
end
