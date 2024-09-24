require "application_system_test_case"

class ChallengesTest < ApplicationSystemTestCase
  setup do
    @challenge = challenges(:one)
    sign_in users(:admin)
  end

  test "visiting the index as admin" do
    sign_in users(:admin)

    visit challenges_url
    assert_selector "h1", text: "Challenges"
    assert_selector "th", text: "Group ID"
    assert_selector "th", text: "Points To Win"
    assert_selector "th", text: "Actions"

    assert_selector "a", text: "New Challenge"
  end

  test "visiting the index as team" do
    sign_out users(:admin)
    team = users(:team_one)
    sign_in team

    # Give team permission for group 1
    GroupPermission.create(user: team, group_id: 1)

    visit challenges_url
    assert_selector "h1", text: "Challenges"
    assert_no_selector "th", text: "Group ID"
    assert_selector "th", text: "Points To Win"
    assert_selector "th", text: "Obtained Points"

    assert_no_selector "th", text: "Actions"
    assert_no_selector "a", text: "New Challenge"

    # Should only see challenges from group 1
    assert_text challenges(:one).description
    assert_no_text challenges(:three).description
  end

  test "should create challenge as admin" do
    visit challenges_url
    click_on "New Challenge"

    fill_in "Number", with: 370323
    fill_in "Description", with: "New challenge description"
    fill_in "Points", with: @challenge.points
    fill_in "Group ID", with: 1
    click_on "Create Challenge"

    assert_text "Challenge was successfully created"
    assert_text "Group ID: 1"
  end

  test "should update Challenge as admin" do
    visit challenge_url(@challenge)
    click_on "Edit this Challenge", match: :first

    fill_in "Description", with: @challenge.description + " (updated)"
    fill_in "Group ID", with: 2
    click_on "Update Challenge"

    assert_text "Challenge was successfully updated"
    assert_text "Group ID: 2"
  end

  test "should destroy Challenge as admin" do
    visit challenge_url(@challenge)
    accept_confirm do
      click_on "Destroy this Challenge", match: :first
    end

    assert_text "Challenge was successfully destroyed"
  end

  test "team user cannot create, update, or destroy challenges" do
    sign_out :user
    sign_in users(:team_one)

    visit challenges_url
    assert_no_selector "a", text: "New Challenge"

    visit challenge_url(@challenge)
    assert_no_selector "a", text: "Edit this challenge"
    assert_no_selector "a", text: "Destroy this challenge"
  end
end
