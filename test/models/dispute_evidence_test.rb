require 'test_helper'

class DisputeEvidenceTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    evidence = FactoryBot.build(:dispute_evidence)
    assert evidence.valid?
  end

  test "should require evidence_type" do
    evidence = FactoryBot.build(:dispute_evidence, evidence_type: nil)
    assert_not evidence.valid?
  end

  test "should require valid evidence_type" do
    evidence = FactoryBot.build(:dispute_evidence, evidence_type: "invalid")
    assert_not evidence.valid?
  end

  test "should compute content_hash from file_url" do
    evidence = FactoryBot.create(:dispute_evidence, file_url: "https://example.com/test.jpg")
    assert_not_nil evidence.content_hash
  end

  test "scope photos should return only photo evidence" do
    photo = FactoryBot.create(:dispute_evidence, evidence_type: "photo")
    doc = FactoryBot.create(:dispute_evidence, evidence_type: "document")

    assert_includes DisputeEvidence.photos, photo
    assert_not_includes DisputeEvidence.photos, doc
  end
end
