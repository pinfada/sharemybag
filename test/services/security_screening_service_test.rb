require 'test_helper'

class SecurityScreeningServiceTest < ActiveSupport::TestCase
  def setup
    @user = FactoryBot.create(:marketplace_user)
  end

  test "should screen user and return cleared status" do
    service = SecurityScreeningService.new(@user)
    screening = service.screen_user!

    assert_equal "cleared", screening.status
    assert_equal "sanctions", screening.screening_type
    assert_not screening.expired?
  end

  test "should reuse recent valid screening" do
    service = SecurityScreeningService.new(@user)
    first_screening = service.screen_user!
    second_screening = service.screen_user!

    assert_equal first_screening.id, second_screening.id
  end

  test "aml_check should flag high value transactions" do
    transaction = FactoryBot.create(:marketplace_transaction, amount_cents: 600000, sender: @user)
    service = SecurityScreeningService.new(@user)
    screening = service.aml_check!(transaction)

    assert_equal "aml", screening.screening_type
    assert_equal "flagged", screening.status
  end

  test "aml_check should skip for low value transactions" do
    transaction = FactoryBot.create(:marketplace_transaction, amount_cents: 5000, sender: @user)
    service = SecurityScreeningService.new(@user)
    screening = service.aml_check!(transaction)

    assert_nil screening
  end

  test "aml_check should flag new users with high value" do
    new_user = FactoryBot.create(:marketplace_user, created_at: 1.day.ago)
    transaction = FactoryBot.create(:marketplace_transaction, amount_cents: 200000, sender: new_user)
    service = SecurityScreeningService.new(new_user)
    screening = service.aml_check!(transaction)

    assert_equal "flagged", screening.status
    assert screening.match_details.include?("new_user")
  end
end
