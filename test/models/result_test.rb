require "test_helper"

class ResultTest < ActiveSupport::TestCase
  setup do
    @result = results(:challenge_one_by_team_one)
  end

  test "total points adds up" do
    @result.bonus_points = 200
    @result.regular_points = 1500
    assert_equal 1700, @result.total_points
  end

  test "status is 'Not Attempted' when total points are 0" do
    @result.regular_points = 0
    @result.bonus_points = 0
    assert_equal "Not Attempted", @result.status
  end

  test "status is 'Completed' when regular points are greater than or equal to challenge points" do
    @result.regular_points = @result.challenge.points
    assert_equal "Completed", @result.status
  end

  test "status is 'Partially Completed' when total points are greater than 0 but regular points are less than challenge points" do
    @result.regular_points = @result.challenge.points - 1
    @result.bonus_points = 1
    assert_equal "Partially Completed", @result.status
  end

  test "after_update_data returns expected structure" do
    json = @result.after_update_data
    assert_equal [ :id, :user_id, :challenge_id, :regular_points, :bonus_points, :status, :total_points, :updated_by ], json.keys
  end
end
