require "application_system_test_case"

class ScoringTest < ApplicationSystemTestCase
  setup do
    @scorer = users(:scorer)
    @team = users(:team_one)
    @challenge = challenges(:one)
    sign_in @scorer
  end

  test "visiting the scoring interface" do
    visit scoring_url
    assert_selector "h1", text: "Scoreboard"
  end

  test "updating scores" do
    visit scoring_score_url(@team)

    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: 50
      fill_in id: "bonusPoints_#{@challenge.id}", with: 10
    end
    # Wait for the AJAX request to complete
    sleep 2

    # Verify that the score was updated in the database
    result = Result.find_by(challenge: @challenge, user: @team)
    assert_equal 50, result.regular_points
    assert_equal 10, result.bonus_points
  end

  test "non-scorer cannot access scoring interface" do
    sign_out @scorer
    sign_in @team
    visit scoring_url
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path
  end

  test "non-team user cannot be scored" do
    admin = users(:admin)
    sign_in admin

    visit scoring_score_path(admin)
    assert_current_path root_path
    assert_text "Only teams can be scored."
  end
end
