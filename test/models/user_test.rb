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

  # The uniqueness validation is a SELECT followed by an INSERT and two requests can
  # interleave between them; the unique index is what actually holds. insert_all!
  # goes round Active Record the way a bulk write or a console fix would.
  test "a duplicate name is refused by the database, not just by the validation" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.insert_all!([ { email: "another@bedlamtheatre.test", name: users(:team_one).name,
                           encrypted_password: "NA", role: 0,
                           created_at: Time.current, updated_at: Time.current } ])
    end
  end

  # has_many :group_permissions, dependent: :delete_all only helps when the delete
  # goes through Active Record. The foreign key now cascades, so the two agree.
  test "the database takes a user's group permissions with them" do
    user = users(:team_three)
    permission = GroupPermission.create!(user: user, group_id: 7)

    User.where(id: user.id).delete_all

    assert_not GroupPermission.exists?(permission.id)
  end

  test "destroying a user with no results succeeds" do
    user = users(:team_three)

    assert user.destroy, "Expected an unscored team to be destroyable"
    assert_not User.exists?(user.id)
  end

  test "destroying a user with non-zero results is refused" do
    user = users(:team_one)
    GroupPermission.create!(user: user, group_id: 1)

    # Without dependent: on the associations this raised InvalidForeignKey
    # instead of returning false.
    assert_not user.destroy
    assert User.exists?(user.id)
  end
end
