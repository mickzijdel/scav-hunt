require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  def setup
    @admin = users(:admin)
    @team = users(:team_one)
    @scorer = users(:scorer)
    @result = results(:challenge_one_by_team_one)
  end

  test "visiting the home page as guest" do
    visit root_path

    assert_selector "h1", text: "Scoreboard"
    assert_selector "h2", text: "Time Remaining:"
    assert_selector "[data-scoreboard-target='timer']"

    assert_selector "table" do
      assert_selector "th", text: "Rank"
      assert_selector "th", text: "Team"
      assert_selector "th", text: "Score"
    end

    assert_selector "nav.navbar" do
      assert_selector "a.nav-link", text: "Scoreboard"
      assert_selector "a.nav-link", text: "Log In"
      assert_no_selector "button.nav-link", text: "Log Out"
      assert_no_selector "a", text: "Challenges"
      assert_no_selector "a", text: "Users"
      assert_no_selector "a", text: "Scoring"
    end
  end

  test "visiting the home page as team user" do
    sign_in @team
    visit root_path

    assert_selector "h1", text: "Scoreboard"
    assert_selector "span.navbar-text", text: "Welcome #{@team.name}"

    assert_selector "nav.navbar" do
      assert_selector "a.nav-link", text: "Scoreboard"
      assert_selector "a.nav-link", text: "Challenges"
      assert_selector "button.nav-link", text: "Log Out"

      assert_no_selector "a.nav-link", text: "Users"
      assert_no_selector "a.nav-link", text: "Scoring"
    end
  end

  test "visiting the home page as scorer user" do
        sign_in @scorer
        visit root_path

        assert_selector "h1", text: "Scoreboard"
        assert_selector "span.navbar-text", text: "Welcome #{@scorer.name}"

        assert_selector "nav.navbar" do
          assert_selector "a.nav-link", text: "Scoring"
          assert_selector "a.nav-link", text: "Challenges"

          assert_no_selector "a.nav-link", text: "Users"
        end
  end

  test "scoreboard updates" do
    visit root_path

    initial_content = find("[data-scoreboard-target='tableBody']").text

    # Simulate scoreboard update
    @result.update(regular_points: @result.regular_points + 10)

    # Wait for the update interval (adjust if necessary)
    sleep 6

    updated_content = find("[data-scoreboard-target='tableBody']").text
    assert_not_equal initial_content, updated_content, "Scoreboard should have updated"
  end

  test "navigation links work correctly" do
    sign_in @team
    visit root_path

    click_on "Challenges"
    assert_current_path challenges_path

    visit root_path
    click_on "Log Out"
    assert_current_path root_path
  end
end
