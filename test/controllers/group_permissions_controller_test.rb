require "test_helper"

class GroupPermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @team = users(:team_one)
  end

  test "a team cannot grant itself a group" do
    sign_in @team

    assert_no_difference -> { GroupPermission.count } do
      post group_permissions_path, params: { user_id: @team.id, group_id: 3, permitted: "true" }
    end

    assert_redirected_to root_path
  end

  test "a scorer can grant a group" do
    sign_in users(:scorer)

    assert_difference -> { GroupPermission.count }, 1 do
      post group_permissions_path, params: { user_id: @team.id, group_id: 3, permitted: "true" }
    end

    assert_response :success
    assert @team.can_see_group?(3)
  end

  test "a scorer can revoke a group" do
    sign_in users(:scorer)
    GroupPermission.create!(user: @team, group_id: 3)

    assert_difference -> { GroupPermission.count }, -1 do
      post group_permissions_path, params: { user_id: @team.id, group_id: 3, permitted: "false" }
    end

    assert_response :success
    assert_not @team.can_see_group?(3)
  end

  test "the response renders the checkbox back in the state the database ended up in" do
    sign_in users(:scorer)

    post group_permissions_path, params: { user_id: @team.id, group_id: 3, permitted: "true" }

    assert_match "group_permission_#{@team.id}_3", response.body
    assert_match "checked", response.body
  end
end
