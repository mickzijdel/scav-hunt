require "test_helper"

# ScoringChannel and its hand-written `subscribed` check are gone; every live region
# now runs over Turbo::StreamsChannel. The property those tests protected -- a team
# cannot watch a rival's live scores -- is now carried by the signed stream name, so
# it is asserted here (a name cannot be forged) and in
# test/controllers/stream_subscriptions_test.rb (a name is only rendered into a page
# its owner is allowed to see).
class TurboStreamsChannelTest < ActionCable::Channel::TestCase
  tests Turbo::StreamsChannel

  test "a correctly signed stream name is accepted" do
    stub_connection

    subscribe signed_stream_name: signed_name_for([ users(:team_one), :scoring ])

    assert subscription.confirmed?
    assert_has_stream "#{users(:team_one).to_gid_param}:scoring"
  end

  test "an unsigned stream name is rejected" do
    stub_connection

    subscribe signed_stream_name: "#{users(:team_two).to_gid_param}:scoring"

    assert subscription.rejected?,
           "Guessing a rival's stream name must not be enough to watch their live scores"
  end

  test "a tampered signature is rejected" do
    stub_connection

    subscribe signed_stream_name: "#{signed_name_for([ users(:team_two), :scoring ])}x"

    assert subscription.rejected?
  end

  test "a missing stream name is rejected rather than raising" do
    stub_connection

    subscribe

    assert subscription.rejected?
  end

  private

  def signed_name_for(streamables)
    Turbo::StreamsChannel.signed_stream_name(streamables)
  end
end
