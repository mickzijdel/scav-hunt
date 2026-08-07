require "test_helper"

class StatisticsServiceTest < ActiveSupport::TestCase
  def setup
    @team1 = users(:team_one)
    @team2 = users(:team_two)
    @result1 = results(:challenge_one_by_team_one)
    @result2 = results(:challenge_one_by_team_two)
  end

  test "points_over_time returns correct data structure" do
    data = StatisticsService.points_over_time(:created_at)

    assert_kind_of Array, data
    assert_includes data.first, "timestamps"
    assert_equal 4, data.size, "Not all teams have a series." # timestamps + 3 teams
    assert data.all? { |inner_data| inner_data.size == data.first.size }, "Not all series have the same size"
  end

  test "points_over_time calculates points correctly" do
    data = StatisticsService.points_over_time(:created_at)

    team1_data = data.find { |d| d.first == @team1.name }
    team2_data = data.find { |d| d.first == @team2.name }

    assert_equal 1100, team1_data.last # 1500 + 0 - 500 + 100
    assert_equal 1100, team2_data.last # 800 + 200 + 0 + 100
  end

  test "points_over_time handles empty results" do
    Result.delete_all
    data = StatisticsService.points_over_time(:created_at)

    assert_equal 4, data.size, "Not all teams have a series."
    assert data.all? { |inner_data| inner_data.size == data.first.size }, "Not all series have the same size"
    assert_operator data.first.size, :>, 1, "Chart has no time axis at all"
    assert data.drop(1).all? { |series| series.drop(1).all?(&:zero?) }, "Teams should be flat at zero"
  end

  test "points_over_time survives an unset chart_start_time" do
    assert_nil Setting.get("chart_start_time"), "Fixture setup changed; this test no longer covers the nil path"

    assert_nothing_raised { StatisticsService.points_over_time(:created_at) }
  end

  test "points_over_time survives an unset scoreboard_end_time" do
    Setting.find_by(key: "scoreboard_end_time").destroy

    assert_nothing_raised { StatisticsService.points_over_time(:created_at) }
  end
end
