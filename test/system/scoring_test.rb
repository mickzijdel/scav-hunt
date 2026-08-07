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

    # Commit the two inputs one at a time. Both save on `change`, which only fires once
    # focus leaves the field, and the handler posts BOTH values read from the DOM as a
    # fire-and-forget request with no sequencing. Filling them back-to-back therefore put
    # two saves in flight at once and they raced: the later-landing response won, and its
    # stale payload also rewrote the other input. Selenium's per-keystroke typing latency
    # usually let them serialise; Playwright fills instantly and exposed the race. Waiting
    # for each save to land keeps only one in flight. (App-level bug, out of scope here.)
    within "tr", text: @challenge.description do
      fill_in id: "regularPoints_#{@challenge.id}", with: 50
      # Nothing takes focus after a fill_in, so blur explicitly or `change` never fires.
      find_by_id("regularPoints_#{@challenge.id}").send_keys(:tab)
    end

    # team_one's fixture results are 1500 + 0 and -500 + 100 (total 1100), so replacing
    # the 1500 with 50 and nothing else totals -350.
    assert_selector "[data-scoring-target='totalPoints']", text: "-350", wait: 10

    within "tr", text: @challenge.description do
      fill_in id: "bonusPoints_#{@challenge.id}", with: 10
      find_by_id("bonusPoints_#{@challenge.id}").send_keys(:tab)
    end

    # Wait for the save to land rather than sleeping. 50 + 10 alongside the other fixture
    # result totals -340 -- a value only reachable once BOTH fields have persisted.
    assert_selector "[data-scoring-target='totalPoints']", text: "-340", wait: 10

    # Verify that the score was updated in the database
    result = Result.find_by(challenge: @challenge, user: @team)
    assert_equal 50, result.regular_points
    assert_equal 10, result.bonus_points

    # Verify that the UI reflects the changes
    within "tr", text: @challenge.description do
      assert_field id: "regularPoints_#{@challenge.id}", with: "50"
      assert_field id: "bonusPoints_#{@challenge.id}", with: "10"
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
