require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  def setup
    @admin = users(:admin)
    @team = users(:team_one)
    @scorer = users(:scorer)
    @result = results(:challenge_one_by_team_one)

    Setting.set("scoreboard_visible", "true")
    Setting.set("scoreboard_end_time", DateTime.new(2024, 9, 27, 14, 0, 0, "+01:00").to_s)
  end

  # These assertions used to sleep past one 5s poll to prove the repainted table still
  # carried the viewer's own column set. There is no poller any more: saving a result
  # broadcasts a page refresh on the :scoreboard stream and every viewer re-renders
  # the page for themselves. So trigger a real change and wait for the new score to
  # land, which is both faster and a stronger claim than "some time passed".
  def assert_live_refresh_keeps_columns(count)
    score = find("tr[data-team-id='#{@team.id}'] [data-score]")
    updated_score = score.text.to_i + 10

    @result.update!(regular_points: @result.regular_points + 10)

    assert_selector "tr[data-team-id='#{@team.id}'] [data-score]", text: updated_score.to_s

    all("#scoreboard_rows tr").each do |row|
      assert_equal count, row.all("td").count, "Content row does not have #{count} td elements"
    end
  end

  # Rank / Team / Score and none of the scorer-only completion columns. Asserted
  # identically by the guest and signed-in-team tests, so it lives here once.
  def assert_public_scoreboard_table
    assert_selector "table" do
      assert_selector "th", text: "Rank"
      assert_selector "th", text: "Team"
      assert_selector "th", text: "Score"
      assert_no_selector "th", text: "Completed"
      assert_no_selector "th", text: "Partially Completed"
      assert_no_selector "th", text: "Not Attempted"

      all("thead tr").each do |row|
        assert_equal 3, row.all("th").count, "Header row does not have 3 th elements"
      end

      all("tbody tr").each do |row|
        assert_equal 3, row.all("td").count, "Content row does not have 3 td elements"
      end
    end

    assert_live_refresh_keeps_columns 3
  end

  test "visiting the home page as guest" do
    visit root_path

    assert_selector "h1", text: "Scoreboard"
    # The "Time Remaining:" heading was deliberately removed from the view; the
    # timer itself is the assertion that matters.
    assert_selector "#timer"

    assert_public_scoreboard_table
  end

  test "Checking the navbar as a guest" do
    visit root_path

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

    assert_public_scoreboard_table
  end

  test "checking the navbar as team user" do
    sign_in @team
    visit root_path
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

    assert_selector "table" do
      assert_selector "th", text: "Rank"
      assert_selector "th", text: "Team"
      assert_selector "th", text: "Score"
      assert_selector "th", text: "Completed"
      assert_selector "th", text: "Partially Completed"
      assert_selector "th", text: "Not Attempted"

      all("table thead tr").each do |row|
        assert_equal 6, row.all("th").count, "Header row does not have 6 td elements"
       end

       all("table tbody tr").each do |row|
         assert_equal 6, row.all("td").count, "Content row does not have 6 td elements"
       end
    end

    assert_live_refresh_keeps_columns 6
  end

  test "checking the navbar as a scorer user" do
    sign_in @scorer
    visit root_path

    assert_selector "nav.navbar" do
      assert_selector "a.nav-link", text: "Scoreboard"
      assert_selector "a.nav-link", text: "Scoring"
      assert_selector "a.nav-link", text: "Challenges"
      assert_selector "button.nav-link", text: "Log Out"

      assert_no_selector "a.nav-link", text: "Users"
    end
  end

  test "scoreboard updates" do
    visit root_path

    score = "tr[data-team-id='#{@team.id}'] [data-score]"
    assert_selector score, text: @team.total_points.to_s

    # Simulate scoreboard update. No poll interval to wait out: the save broadcasts
    # a page refresh and the open page re-renders itself.
    @result.update!(regular_points: @result.regular_points + 10)

    assert_selector score, text: @team.reload.total_points.to_s, wait: 10
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

  test "scoreboard respects visibility setting" do
    visit root_path
    assert_selector "table", count: 1

    Setting.set("scoreboard_visible", "0")
    visit root_path
    assert_no_selector "table"
    assert_text "The scoreboard is currently not visible."
  end

  test "scoreboard end time is displayed and updates" do
    # The shared setup ends the hunt in 2024, which renders "Time's up!" rather
    # than a countdown, so this test has to put the end time back in the future.
    Setting.set("scoreboard_end_time", (DateTime.now.utc + 2.hours).to_s)

    visit root_path
    assert_selector "#timer", text: /\d+h \d+m \d+s/

    new_end_time = DateTime.now.utc + 1.day
    Setting.set("scoreboard_end_time", new_end_time.to_s)

    visit root_path
    assert_selector "#timer", text: /23h 59m \d+s/
  end
end
