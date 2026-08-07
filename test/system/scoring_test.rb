require "application_system_test_case"

class ScoringTest < ApplicationSystemTestCase
  setup do
    @scorer = users(:scorer)
    @admin = users(:admin)
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

    # Both fields are filled back-to-back on purpose. Each input is its own form
    # carrying only its own column, so the two saves cannot overwrite one another --
    # which the previous handler did, silently reverting whichever field lost the
    # race in both the UI and the database. The test used to work around that by
    # committing one field at a time and waiting for each save to land.
    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: 50
      # Nothing takes focus after a fill_in, so blur explicitly or `change` never fires.
      find_by_id("regularPoints_#{@challenge.id}").send_keys(:tab)
      fill_in id: "bonusPoints_#{@challenge.id}", with: 10
      find_by_id("bonusPoints_#{@challenge.id}").send_keys(:tab)
    end

    # team_one's fixture results are 1500 + 0 and -500 + 100 (total 1100), so
    # replacing the 1500 with 50 + 10 totals -340 -- a value only reachable once
    # BOTH saves have landed without clobbering each other.
    assert_selector "#scoring_total_points", text: "-340"

    # Verify that the score was updated in the database
    result = Result.find_by(challenge: @challenge, user: @team)
    assert_equal 50, result.regular_points
    assert_equal 10, result.bonus_points

    # Verify that the UI reflects the changes
    within "tr", text: @challenge.description do
      assert_field id: "regularPoints_#{@challenge.id}", with: "50"
      assert_field id: "bonusPoints_#{@challenge.id}", with: "10"
      assert_text "Partially Completed"
    end
  end

  test "awarding full points fills in the challenge's points" do
    visit scoring_score_url(@team)

    within "tr", text: @challenge.description do
      click_on "Full Points"
      assert_field id: "regularPoints_#{@challenge.id}", with: @challenge.points.to_s
      assert_text "Completed"
    end

    assert_equal @challenge.points, Result.find_by(challenge: @challenge, user: @team).regular_points
  end

  test "a blank score is refused and the stored value comes back" do
    visit scoring_score_url(@team)

    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: ""
      find_by_id("regularPoints_#{@challenge.id}").send_keys(:tab)
    end

    assert_text "Regular points can't be blank"
    assert_field id: "regularPoints_#{@challenge.id}", with: "1500"
    assert_equal 1500, Result.find_by(challenge: @challenge, user: @team).regular_points
  end

  # Nothing covered this before, and it is the whole point of the feature: a score
  # entered by one scorer has to show up on the other scorers' screens without them
  # reloading. Both sessions sit on the same team's scoring page.
  test "a score entered by one scorer appears in another scorer's browser" do
    visit scoring_score_url(@team)
    assert_field id: "regularPoints_#{@challenge.id}", with: "1500"

    using_session :second_scorer do
      sign_in @admin
      visit scoring_score_url(@team)
      assert_field id: "regularPoints_#{@challenge.id}", with: "1500"
    end

    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: 175
      find_by_id("regularPoints_#{@challenge.id}").send_keys(:tab)
    end
    assert_selector "#scoring_total_points", text: "-225"

    using_session :second_scorer do
      assert_field id: "regularPoints_#{@challenge.id}", with: "175"
      assert_selector "#scoring_total_points", text: "-225"
      within "tr", text: @challenge.description do
        assert_text "Partially Completed"
      end
    end
  end

  # The other half of the same promise: the team itself is watching /challenges.
  test "a score entered by a scorer appears on the team's own challenge list" do
    GroupPermission.create!(user: @team, group_id: @challenge.group_id)

    # setup's `sign_in @scorer` is a Warden on_next_request hook, so this session has
    # to make its request first -- otherwise the team's session consumes it and this
    # browser stays signed out.
    visit scoring_score_url(@team)

    using_session :team do
      sign_in @team
      visit challenges_url
      assert_selector "##{ActionView::RecordIdentifier.dom_id(@challenge, :row)}", text: "1500"
    end

    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: 42
      find_by_id("regularPoints_#{@challenge.id}").send_keys(:tab)
    end
    assert_selector "#scoring_total_points", text: "-358"

    using_session :team do
      assert_selector "##{ActionView::RecordIdentifier.dom_id(@challenge, :row)}", text: "42"
      assert_selector "#team_total_points", text: "-358"
    end
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
