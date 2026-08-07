require "test_helper"

class ScoringChannelTest < ActionCable::Channel::TestCase
  test "a team can subscribe to its own stream" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: users(:team_one).id

    assert subscription.confirmed?
    assert_has_stream_for users(:team_one)
  end

  test "a team cannot subscribe to another team's stream" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: users(:team_two).id

    assert subscription.rejected?, "A team must not be able to watch a rival's live scores"
  end

  test "a scorer can subscribe to any team's stream" do
    stub_connection current_user: users(:scorer)

    subscribe user_id: users(:team_one).id

    assert subscription.confirmed?
    assert_has_stream_for users(:team_one)
  end

  test "an unknown user_id is rejected rather than raising" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: -1

    assert subscription.rejected?
  end

  test "a team cannot write a score" do
    stub_connection current_user: users(:team_one)
    subscribe user_id: users(:team_one).id

    assert_no_difference -> { Result.count } do
      perform :receive, "challenge_id" => challenges(:three).id,
                        "user_id" => users(:team_one).id,
                        "regular_points" => 300,
                        "bonus_points" => 0
    end
  end

  test "a scorer can write a score" do
    stub_connection current_user: users(:scorer)
    subscribe user_id: users(:team_one).id

    assert_difference -> { Result.count }, 1 do
      perform :receive, "challenge_id" => challenges(:three).id,
                        "user_id" => users(:team_one).id,
                        "regular_points" => 300,
                        "bonus_points" => 0
    end
  end
end
