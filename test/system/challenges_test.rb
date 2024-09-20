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
    assert_selector "th", text: "Points"
    assert_selector "a", text: "New Challenge"
  end

  test "visiting the index as team" do
    sign_out users(:admin)
    sign_in users(:team_one)

    visit challenges_url
    assert_selector "h1", text: "Challenges"
    assert_selector "th", text: "Max Points"
    assert_selector "th", text: "Obtained Points"

    assert_no_selector "th", text: "Actions"
    assert_no_selector "a", text: "New Challenge"
  end

  test "should create challenge as admin" do
    visit challenges_url
    click_on "New Challenge"
    fill_in "Number", with: 370323
    fill_in "Description", with: "New challenge description"
    fill_in "Points", with: @challenge.points
    click_on "Create Challenge"
    assert_text "Challenge was successfully created"
  end

  test "should update Challenge as admin" do
    visit challenge_url(@challenge)
    click_on "Edit this challenge", match: :first
    fill_in "Description", with: @challenge.description + " (updated)"
    click_on "Update Challenge"
    assert_text "Challenge was successfully updated"
  end

  test "should destroy Challenge as admin" do
    visit challenge_url(@challenge)
    accept_confirm do
      click_on "Destroy this challenge", match: :first
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
