require "test_helper"

class ChallengeTest < ActiveSupport::TestCase
  test "should not save challenge without number" do
    challenge = Challenge.new(description: "Test Challenge", points: 100)
    assert_not challenge.save, "Saved the challenge without a number"
  end

  test "should not save challenge without description" do
    challenge = Challenge.new(number: 1, points: 100)
    assert_not challenge.save, "Saved the challenge without a description"
  end

  test "should not save challenge without points" do
    challenge = Challenge.new(number: 1, description: "Test Challenge")
    assert_not challenge.save, "Saved the challenge without points"
  end

  test "should not save challenge with duplicate number" do
    existing_challenge = challenges(:one)
    challenge = Challenge.new(number: existing_challenge.number, description: "Test Challenge", points: 100)
    assert_not challenge.save, "Saved the challenge with a duplicate number"
  end

  test "title should include number and description" do
    challenge = challenges(:one)
    expected_title = "Challenge #{challenge.number} - \"#{challenge.description}\""
    assert_equal expected_title, challenge.title
  end
end
