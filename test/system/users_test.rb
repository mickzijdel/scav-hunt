require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @user = users(:team_one)
    sign_in @admin
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Users"
  end

  test "creating a User" do
    visit users_url
    click_on "New User"

    fill_in "Name", with: "New User"
    fill_in "Email", with: "newuser@example.com"
    select "team", from: "Role"
    fill_in "Password", with: "password"
    fill_in "Password confirmation", with: "password"
    click_on "Create User"

    assert_text "User was successfully created"
  end

  test "updating a User" do
    visit users_url
    click_on "Edit", match: :first

    fill_in "Name", with: "Updated User"
    click_on "Update User"

    assert_text "User was successfully updated"
  end

  # TODO: More comprehensive tests with password updates

  test "destroying a User" do
    visit users_url
    page.accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "User was successfully destroyed"
  end

  test "non-admin cannot access users management" do
    sign_out @admin
    sign_in @user
    visit users_url
    assert_text "Access denied"
    assert_current_path root_path
  end
end