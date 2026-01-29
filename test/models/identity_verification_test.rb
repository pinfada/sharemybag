require 'test_helper'

class IdentityVerificationTest < ActiveSupport::TestCase
  def setup
    @verification = FactoryBot.create(:identity_verification)
  end

  test "should be valid with valid attributes" do
    assert @verification.valid?
  end

  test "should require document_type" do
    @verification.document_type = nil
    assert_not @verification.valid?
  end

  test "should require valid document_type" do
    @verification.document_type = "invalid"
    assert_not @verification.valid?
  end

  test "should accept passport" do
    @verification.document_type = "passport"
    assert @verification.valid?
  end

  test "should accept id_card" do
    @verification.document_type = "id_card"
    assert @verification.valid?
  end

  test "should accept driver_license" do
    @verification.document_type = "driver_license"
    assert @verification.valid?
  end

  test "should require valid status" do
    @verification.status = "invalid"
    assert_not @verification.valid?
  end

  test "verify! should set status to verified" do
    admin = FactoryBot.create(:admin_user)
    @verification.verify!(admin)
    assert_equal "verified", @verification.status
    assert_not_nil @verification.verified_at
    assert_equal admin.id, @verification.verified_by_id
  end

  test "reject! should set status to rejected with reason" do
    admin = FactoryBot.create(:admin_user)
    @verification.reject!(admin, "Document expired")
    assert_equal "rejected", @verification.status
    assert_equal "Document expired", @verification.rejection_reason
  end
end
