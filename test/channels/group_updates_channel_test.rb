require "test_helper"

class GroupUpdatesChannelTest < ActionCable::Channel::TestCase
  test "a team can subscribe to its own stream" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: users(:team_one).id

    assert subscription.confirmed?
    assert_has_stream_for users(:team_one)
  end

  test "a team cannot subscribe to another team's stream" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: users(:team_two).id

    assert subscription.rejected?,
           "This stream carries the rendered challenge list, so it must not leak across users"
  end

  test "a scorer can subscribe to any team's stream" do
    stub_connection current_user: users(:scorer)

    subscribe user_id: users(:team_one).id

    assert subscription.confirmed?
  end

  test "an unknown user_id is rejected rather than raising" do
    stub_connection current_user: users(:team_one)

    subscribe user_id: -1

    assert subscription.rejected?
  end
end
