require "application_system_test_case"

class GroupPermissionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @scorer = users(:scorer)
    @team = users(:team_one)
    @challenge_group1 = challenges(:one)
    @challenge_group2 = challenges(:three)
    @challenge_group3 = challenges(:five)
  end

  test "admin can manage group permissions on index page" do
    sign_in @admin
    # Must exist before the page renders, or the checkbox comes back unchecked.
    GroupPermission.create!(user: @team, group_id: 1)

    visit group_permissions_path

    assert_selector "h1", text: "Manage Group Permissions"

    # Check initial state
    assert_checked_field "group_permission_#{@team.id}_1"
    assert_unchecked_field "group_permission_#{@team.id}_2"
    assert_unchecked_field "group_permission_#{@team.id}_3"

    # Toggle permissions
    uncheck "group_permission_#{@team.id}_1"
    check "group_permission_#{@team.id}_2"

    # There is no .loading-indicator anywhere in the app, so the assertion that
    # used to sit here returned instantly and the reload below raced the fetch.
    # Wait on the state the request actually changes.
    assert_eventually(message: "group 1 permission was never revoked") do
      !GroupPermission.exists?(user: @team, group_id: 1)
    end
    assert_eventually(message: "group 2 permission was never granted") do
      GroupPermission.exists?(user: @team, group_id: 2)
    end

    # Reload page to verify changes persisted
    visit group_permissions_path

    assert_unchecked_field "group_permission_#{@team.id}_1"
    assert_checked_field "group_permission_#{@team.id}_2"
    assert_unchecked_field "group_permission_#{@team.id}_3"
  end

  test "scorer can manage group permissions on score page" do
    sign_in @scorer
    # Must exist before the page renders, or the checkbox comes back unchecked.
    GroupPermission.create!(user: @team, group_id: 1)

    visit scoring_score_path(@team)

    assert_selector "h1", text: "Scoring #{@team.name}"

    # Check initial state
    assert_checked_field "group_permission_#{@team.id}_1"
    assert_unchecked_field "group_permission_#{@team.id}_2"
    assert_unchecked_field "group_permission_#{@team.id}_3"

    # Toggle permissions
    uncheck "group_permission_#{@team.id}_1"
    check "group_permission_#{@team.id}_2"

    # There is no .loading-indicator anywhere in the app, so the assertion that
    # used to sit here returned instantly and the reload below raced the fetch.
    # Wait on the state the request actually changes.
    assert_eventually(message: "group 1 permission was never revoked") do
      !GroupPermission.exists?(user: @team, group_id: 1)
    end
    assert_eventually(message: "group 2 permission was never granted") do
      GroupPermission.exists?(user: @team, group_id: 2)
    end

    # Reload page to verify changes persisted
    visit scoring_score_path(@team)

    assert_unchecked_field "group_permission_#{@team.id}_1"
    assert_checked_field "group_permission_#{@team.id}_2"
    assert_unchecked_field "group_permission_#{@team.id}_3"
  end

  test "team can only see challenges from permitted groups" do
    # Give team permission for group 1 and 2
    GroupPermission.create(user: @team, group_id: 1)
    GroupPermission.create(user: @team, group_id: 2)

    sign_in @team
    visit challenges_path

    assert_selector "h1", text: "Challenges"

    # Should see challenges from group 1 and 2, but not 3
    assert_text @challenge_group1.description
    assert_text @challenge_group2.description
    assert_no_text @challenge_group3.description
  end

  test "admin can see all challenges regardless of group permissions" do
    sign_in @admin
    visit challenges_path

    assert_selector "h1", text: "Challenges"

    # Should see all challenges
    assert_text @challenge_group1.description
    assert_text @challenge_group2.description
    assert_text @challenge_group3.description
  end
end
