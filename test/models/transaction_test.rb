require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
    @traveler = FactoryBot.create(:marketplace_user)
    @shipping_request = FactoryBot.create(:shipping_request, sender: @sender)
    @bid = FactoryBot.create(:bid, shipping_request: @shipping_request, traveler: @traveler, status: "accepted")
  end

  test "should create transaction from accepted bid" do
    transaction = Transaction.create_from_bid(@bid)
    assert_not_nil transaction
    assert_equal "pending", transaction.status
    assert_equal @sender.id, transaction.sender_id
    assert_equal @traveler.id, transaction.traveler_id
  end

  test "should not create transaction from non-accepted bid" do
    @bid.update!(status: "pending")
    assert_nil Transaction.create_from_bid(@bid)
  end

  test "should not create duplicate transaction for same shipping request" do
    Transaction.create_from_bid(@bid)
    assert_nil Transaction.create_from_bid(@bid)
  end

  test "should calculate platform fee at 15%" do
    transaction = Transaction.create_from_bid(@bid)
    expected_fee = (@bid.total_price_cents * 0.15).round
    assert_equal expected_fee, transaction.platform_fee_cents
  end

  test "should calculate traveler payout correctly" do
    transaction = Transaction.create_from_bid(@bid)
    expected_payout = @bid.total_price_cents - transaction.platform_fee_cents
    assert_equal expected_payout, transaction.traveler_payout_cents
  end

  test "pay! should transition to escrow status" do
    transaction = FactoryBot.create(:marketplace_transaction, status: "pending")
    transaction.pay!
    assert_equal "escrow", transaction.status
    assert_not_nil transaction.paid_at
  end

  test "release! should transition to released status" do
    transaction = FactoryBot.create(:marketplace_transaction, status: "escrow")
    transaction.release!
    assert_equal "released", transaction.status
    assert_not_nil transaction.released_at
  end

  test "refund! should transition to refunded status" do
    transaction = FactoryBot.create(:marketplace_transaction, status: "escrow")
    transaction.refund!
    assert_equal "refunded", transaction.status
    assert_not_nil transaction.refunded_at
  end

  test "should validate amount is positive" do
    transaction = FactoryBot.build(:marketplace_transaction, amount_cents: -100)
    assert_not transaction.valid?
  end

  test "should validate status inclusion" do
    transaction = FactoryBot.build(:marketplace_transaction, status: "invalid")
    assert_not transaction.valid?
  end

  test "should validate uniqueness of shipping_request_id" do
    FactoryBot.create(:marketplace_transaction, shipping_request: @shipping_request)
    duplicate = FactoryBot.build(:marketplace_transaction, shipping_request: @shipping_request)
    assert_not duplicate.valid?
  end

  test "amount should return value in currency units" do
    transaction = FactoryBot.create(:marketplace_transaction, amount_cents: 2500)
    assert_equal 25.0, transaction.amount
  end
end
