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
    assert_selector "h1", text: "New User"

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
    # Target a specific row rather than match: :first -- the index is ordered by
    # role then name, so a user created by another test can take the first slot.
    within "tr", text: @user.name do
      click_on "Edit"
    end
    assert_selector "h1", text: /Edit/

    fill_in "Name", with: "Updated User"
    click_on "Update User"

    assert_text "User was successfully updated"
  end

  test "creating a user requires a password" do
    visit users_url
    click_on "New User"
    assert_selector "h1", text: "New User"

    fill_in "Name", with: "New Test User"
    fill_in "Email", with: "newtest@example.com"
    select "team", from: "Role"
    click_on "Create User"

    assert_text "Password can't be blank"

    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_on "Create User"

    assert_text "User was successfully created"
  end

  test "editing a user does not require a password change" do
    visit users_url
    # Target a specific row rather than match: :first -- the index is ordered by
    # role then name, so a user created by another test can take the first slot.
    within "tr", text: @user.name do
      click_on "Edit"
    end
    assert_selector "h1", text: /Edit/

    fill_in "Name", with: "Updated User Name"
    click_on "Update User"

    assert_text "User was successfully updated"
    assert_text "Updated User Name"
  end

  test "editing a user allows optional password change" do
    visit users_url
    # Target a specific row rather than match: :first -- the index is ordered by
    # role then name, so a user created by another test can take the first slot.
    within "tr", text: @user.name do
      click_on "Edit"
    end
    assert_selector "h1", text: /Edit/

    fill_in "Name", with: "Updated User with New Password"
    fill_in "Password", with: "newpassword123"
    fill_in "Password confirmation", with: "newpassword123"
    click_on "Update User"

    assert_text "User was successfully updated"
    assert_text "Updated User with New Password"
  end

  test "editing a user with mismatched passwords shows an error" do
    visit users_url
    # Target a specific row rather than match: :first -- the index is ordered by
    # role then name, so a user created by another test can take the first slot.
    within "tr", text: @user.name do
      click_on "Edit"
    end
    assert_selector "h1", text: /Edit/

    fill_in "Name", with: "Mismatched Password User"
    fill_in "Password", with: "newpassword123"
    fill_in "Password confirmation", with: "differentpassword"
    click_on "Update User"

    assert_text "Password confirmation doesn't match Password"
  end

  test "destroying a User" do
    # Read the id up front; the fixture accessor raises once the row is gone.
    team_three_id = users(:team_three).id

    visit users_url

    # Team 3 is the only fixture team with no results; destroying a scored team
    # is refused on purpose (see below).
    within "tr", text: "Team 3" do
      page.accept_confirm do
        click_on "Destroy"
      end
    end

    assert_text "User was successfully destroyed"
    assert_not User.exists?(team_three_id)
  end

  test "destroying a User with scores is refused" do
    visit users_url

    within "tr", text: "Team 1" do
      page.accept_confirm do
        click_on "Destroy"
      end
    end

    assert_text "Cannot destroy result with non-zero points"
    assert User.exists?(users(:team_one).id), "A scored team must not be deletable"
  end

  test "non-admin cannot access users management" do
    sign_out @admin
    sign_in @user
    visit users_url
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path
  end
end
