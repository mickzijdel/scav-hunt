require "test_helper"

# A signed stream name is a bearer token: whoever holds one can subscribe to it. The
# half of that contract the app owns is never handing one to somebody who should not
# have it, which is what these tests pin down. The other half -- that a name cannot
# be forged -- lives in test/channels/turbo_streams_channel_test.rb.
class StreamSubscriptionsTest < ActionDispatch::IntegrationTest
  setup do
    @team = users(:team_one)
    @rival = users(:team_two)
    GroupPermission.create!(user: @team, group_id: 1)
  end

  test "a team's challenge page subscribes to its own stream and nobody else's" do
    sign_in @team

    get challenges_path

    assert_select "turbo-cable-stream-source[signed-stream-name=?]",
                  signed_name_for([ @team, :challenges ])
    assert_no_match signed_name_for([ @rival, :challenges ]), response.body,
                    "A team must not be handed a rival's stream name"
    assert_no_match signed_name_for([ @team, :scoring ]), response.body,
                    "The scorers' stream is not a team's to subscribe to"
  end

  test "a team cannot open a rival's scoring page and pick up their stream name" do
    sign_in @team

    get scoring_score_path(@rival)

    assert_redirected_to root_path
  end

  test "a scorer's scoring page subscribes to the team it is scoring" do
    sign_in users(:scorer)

    get scoring_score_path(@team)

    assert_select "turbo-cable-stream-source[signed-stream-name=?]",
                  signed_name_for([ @team, :scoring ])
  end

  private

  def signed_name_for(streamables)
    Turbo::StreamsChannel.signed_stream_name(streamables)
  end
end
