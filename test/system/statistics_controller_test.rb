require "application_system_test_case"

class StatisticsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @team1 = users(:team_one)
    @team2 = users(:team_two)
    @challenge = challenges(:one)

    sign_in @admin
  end

  test "visiting the statistics page" do
    visit statistics_path

    assert_selector "h2", text: "Score Over Time (Created At)"
    assert_selector "h2", text: "Score Over Time (Updated At)"

    assert_selector "#createdAtChart"
    assert_selector "#updatedAtChart"
  end

  test "charts are rendered" do
    visit statistics_path

    # Wait for charts to be rendered
    assert_selector ".bb-chart", count: 2, wait: 5

    # Check if team names are present in the legend
    assert_text @team1.name
    assert_text @team2.name
  end

  test "non-admin cannot access statistics page" do
    sign_out @admin
    sign_in @team1

    visit statistics_path
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path
  end

  test "statistics data updates when results change" do
    visit statistics_path

    initial_content = find("#createdAtChart").text

    # Create a new result
    Result.create!(user: @team1, challenge: @challenge, regular_points: 200, bonus_points: 0, created_at: Time.current)

    # Refresh the page
    visit statistics_path

    # Wait for the chart to update
    updated_content = find("#createdAtChart", wait: 5).text
    assert_not_equal initial_content, updated_content, "Chart should have updated with new data"
  end
end
