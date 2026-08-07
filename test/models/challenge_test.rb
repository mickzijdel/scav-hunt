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

  test "two challenges may share a description" do
    duplicate = Challenge.new(number: 991, description: challenges(:one).description, points: 100, group_id: 1)

    assert duplicate.save, duplicate.errors.full_messages.to_sentence
  end

  # The model's uniqueness validation is a SELECT followed by an INSERT, so two CSV
  # imports running at once both pass it. The unique index is what actually stops
  # the second one -- insert_all! goes round Active Record exactly as they would.
  test "a duplicate number is refused by the database, not just by the validation" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Challenge.insert_all!([ challenge_row(number: challenges(:one).number) ])
    end
  end

  test "the database refuses a challenge with a missing required column" do
    %i[ number description points group_id ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation, "#{column} was allowed to be NULL") do
        Challenge.insert_all!([ challenge_row(number: 990).merge(column => nil) ])
      end
    end
  end

  test "group_ids lists every populated group once, in order" do
    assert_equal [ 1, 2, 3 ], Challenge.group_ids
  end

  test "title should include number and description" do
    challenge = challenges(:one)
    expected_title = "Challenge #{challenge.number} - \"#{challenge.description}\""
    assert_equal expected_title, challenge.title
  end

  private

  def challenge_row(number:)
    { number: number, description: "A challenge", points: 100, group_id: 1,
      created_at: Time.current, updated_at: Time.current }
  end
end
