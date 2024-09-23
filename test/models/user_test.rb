require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Test User", email: "test@example.com", password: "password", password_confirmation: "password", role: :team)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = ""
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "password should be present" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "role should be present" do
    @user.role = nil
    assert_not @user.valid?
  end

  test "total_points calculates correctly" do
    user = users(:team_one)
    expected_total = user.results.sum(&:total_points)
    assert_equal expected_total, user.total_points
  end

  test "stats returns correct values" do
    user = users(:team_one)
    stats = user.stats

    assert_includes stats.keys, :completed
    assert_includes stats.keys, :partially_completed
    assert_includes stats.keys, :not_attempted

    total_challenges = Challenge.count
    assert_equal total_challenges, stats[:completed] + stats[:partially_completed] + stats[:not_attempted]
  end

  test "scoreboard_data returns expected structure" do
    user = users(:team_one)
    data = user.scoreboard_data

    assert_equal user.id, data[:id]
    assert_equal user.name, data[:name]
    assert_equal user.total_points, data[:score]
  end

  test "scoreboard_data includes stats for admin" do
    user = users(:team_one)
    admin_ability = Ability.new(users(:admin))
    data = user.scoreboard_data(admin_ability)

    assert_includes data.keys, :completed
    assert_includes data.keys, :partially_completed
    assert_includes data.keys, :not_attempted
  end
end
