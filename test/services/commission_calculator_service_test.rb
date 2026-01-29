require 'test_helper'

class CommissionCalculatorServiceTest < ActiveSupport::TestCase
  test "should calculate 15% platform fee" do
    result = CommissionCalculatorService.new(amount_cents: 10000, currency: 'EUR').calculate
    assert_equal 1500, result[:platform_fee_cents]
  end

  test "should calculate traveler payout" do
    result = CommissionCalculatorService.new(amount_cents: 10000, currency: 'EUR').calculate
    assert_equal 8500, result[:traveler_payout_cents]
  end

  test "should calculate stripe fees for EU" do
    result = CommissionCalculatorService.new(amount_cents: 10000, currency: 'EUR', region: 'EU').calculate
    expected_stripe_fee = (10000 * 0.014 + 25).round
    assert_equal expected_stripe_fee, result[:stripe_fee_cents]
  end

  test "should calculate net platform fee" do
    result = CommissionCalculatorService.new(amount_cents: 10000, currency: 'EUR', region: 'EU').calculate
    assert result[:net_platform_fee_cents] > 0
    assert result[:net_platform_fee_cents] < result[:platform_fee_cents]
  end

  test "should use correct minimums for different currencies" do
    assert_equal 1000, CommissionCalculatorService.minimum_for_currency('EUR')
    assert_equal 5000, CommissionCalculatorService.minimum_for_currency('XOF')
    assert_equal 5000, CommissionCalculatorService.minimum_for_currency('XAF')
    assert_equal 1000, CommissionCalculatorService.minimum_for_currency('USD')
  end

  test "for_bid should calculate from bid" do
    sender = FactoryBot.create(:marketplace_user)
    shipping_request = FactoryBot.create(:shipping_request, sender: sender, weight_kg: 5)
    traveler = FactoryBot.create(:marketplace_user)
    bid = FactoryBot.create(:bid, shipping_request: shipping_request, traveler: traveler, price_per_kg_cents: 1000)

    result = CommissionCalculatorService.for_bid(bid)
    assert_equal 5000, result[:amount_cents]
    assert_equal 750, result[:platform_fee_cents]
    assert_equal 4250, result[:traveler_payout_cents]
  end

  test "net platform fee should not be negative" do
    result = CommissionCalculatorService.new(amount_cents: 100, currency: 'EUR').calculate
    assert result[:net_platform_fee_cents] >= 0
  end
end
