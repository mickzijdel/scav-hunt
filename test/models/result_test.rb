require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "total points adds up" do
    result = results(:challenge_one_by_team_one)

    result.bonus_points = 200
    result.regular_points = 1500

    assert_equal 1700, result.total_points
  end
end
