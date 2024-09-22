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
    visit scoring_url

    within "tr", text: @challenge.description do
      within "td", text: @team.name do
        fill_in "data-scoring-target" => "regularPoints", with: 50
        fill_in "data-scoring-target" => "bonusPoints", with: 10
      end
    end

    # Wait for the AJAX request to complete
    sleep 1

    # Verify that the score was updated in the database
    result = Result.find_by(challenge: @challenge, user: @team)
    assert_equal 50, result.regular_points
    assert_equal 10, result.bonus_points
  end

  test "non-scorer cannot access scoring interface" do
    sign_out @scorer
    sign_in @team
    visit scoring_url
    assert_text "Access denied"
    assert_current_path root_path
  end
end
