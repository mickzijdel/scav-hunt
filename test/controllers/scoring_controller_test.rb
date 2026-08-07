require "test_helper"

# Writes used to arrive over ScoringChannel#receive as well as over this action, and
# the channel test covered who was allowed to write. There is only one write path
# now, so that coverage lives here.
class ScoringControllerTest < ActionDispatch::IntegrationTest
  setup do
    @team = users(:team_one)
    @challenge = challenges(:three)
    @result = results(:challenge_one_by_team_one)
  end

  test "a team cannot write a score" do
    sign_in @team

    assert_no_difference -> { Result.count } do
      post scoring_update_path, params: { challenge_id: @challenge.id, user_id: @team.id, regular_points: 300 }
    end

    assert_redirected_to root_path
  end

  test "a scorer can write a score" do
    sign_in users(:scorer)

    assert_difference -> { Result.count }, 1 do
      post scoring_update_path, params: { challenge_id: @challenge.id, user_id: @team.id, regular_points: 300 }
    end

    assert_response :success
    assert_equal 300, Result.find_by(challenge: @challenge, user: @team).regular_points
  end

  test "a new result created from one field defaults the other to zero" do
    sign_in users(:scorer)

    post scoring_update_path, params: { challenge_id: @challenge.id, user_id: @team.id, bonus_points: 25 }

    result = Result.find_by(challenge: @challenge, user: @team)
    assert_equal 25, result.bonus_points
    assert_equal 0, result.regular_points
  end

  # The bug this replaces: the old handler posted BOTH columns, read out of the DOM,
  # so a save that was only meant to change one of them wrote a stale value over the
  # other. A request that names one column must leave the other exactly as it was.
  test "a save that names one column does not touch the other" do
    sign_in users(:scorer)
    @result.update!(regular_points: 1500, bonus_points: 0)

    post scoring_update_path, params: { challenge_id: @result.challenge_id, user_id: @team.id, bonus_points: 10 }

    @result.reload
    assert_equal 10, @result.bonus_points
    assert_equal 1500, @result.regular_points, "The untouched column was overwritten"
  end

  test "an interleaved pair of single-column saves both survive" do
    sign_in users(:scorer)
    @result.update!(regular_points: 1500, bonus_points: 0)

    # Two requests that each read the row before the other has written, exactly the
    # shape of two scorers saving at the same moment.
    first = Result.find_or_initialize_by(challenge_id: @result.challenge_id, user_id: @team.id)
    second = Result.find_or_initialize_by(challenge_id: @result.challenge_id, user_id: @team.id)

    first.regular_points = 50
    second.bonus_points = 10
    first.save!
    second.save!

    @result.reload
    assert_equal 50, @result.regular_points
    assert_equal 10, @result.bonus_points
  end

  test "a blank value is refused and the stored score is left alone" do
    sign_in users(:scorer)
    @result.update!(regular_points: 1500, bonus_points: 0)

    post scoring_update_path, params: { challenge_id: @result.challenge_id, user_id: @team.id, regular_points: "" }

    assert_response :unprocessable_entity
    assert_equal 1500, @result.reload.regular_points
  end
end
