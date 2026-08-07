require "test_helper"

class GroupPermissionTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @team = users(:team_one)
    @stream = "#{@team.to_gid_param}:challenges"
  end

  test "granting a group re-renders the team's challenge list for them" do
    assert_broadcasts @stream, 1 do
      GroupPermission.create!(user: @team, group_id: 2)
    end
  end

  test "revoking a group re-renders the team's challenge list for them" do
    permission = GroupPermission.create!(user: @team, group_id: 2)

    assert_broadcasts @stream, 1 do
      permission.destroy!
    end
  end

  test "the broadcast only carries the challenges the team may now see" do
    GroupPermission.create!(user: @team, group_id: 1)

    payload = CGI.unescapeHTML(capture_broadcasts(@stream) { GroupPermission.create!(user: @team, group_id: 2) }.last)

    assert_includes payload, challenges(:one).description
    assert_includes payload, challenges(:three).description
    assert_not_includes payload, challenges(:five).description,
                        "A group the team has no permission for must not be broadcast to them"
  end
end
