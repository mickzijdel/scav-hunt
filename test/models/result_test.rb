require "test_helper"

class ResultTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

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

  test "saving a result broadcasts a page refresh to the scoreboard" do
    assert_broadcasts "scoreboard", 1 do
      @result.update!(regular_points: @result.regular_points + 1)
    end
  end

  test "saving a result broadcasts the new score to the scorers watching this team" do
    assert_broadcasts "#{@result.user.to_gid_param}:scoring", 1 do
      @result.update!(regular_points: @result.regular_points + 1)
    end
  end

  test "saving a result broadcasts the new score to the team's own challenge page" do
    assert_broadcasts "#{@result.user.to_gid_param}:challenges", 1 do
      @result.update!(regular_points: @result.regular_points + 1)
    end
  end
end
