require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @team = users(:team_one)
    @scorer = users(:scorer)

    # Set initial settings
    Setting.set("scoreboard_end_time", DateTime.new(2024, 9, 27, 14, 0, 0, "+01:00").to_s)
    Setting.set("scoreboard_visible", "true")
  end

  test "admin can view and update settings" do
    sign_in @admin
    visit settings_path

    assert_selector "h1", text: "Settings"

    # Test updating scoreboard end time
    within "form", id: "settings_form_scoreboard_end_time" do
      find("textarea[name='setting[value]']").fill_in with: "2024-10-01T15:00:00"
      click_button "Update"
    end

    assert_text "Setting \"#{Setting::KEYS["scoreboard_end_time"][:title]}\" updated successfully."
    assert_equal "2024-10-01T15:00:00+00:00", Setting.get("scoreboard_end_time").to_s

    # Test updating scoreboard visibility
    within "form", id: "settings_form_scoreboard_visible" do
      find("textarea[name='setting[value]']").fill_in with: "false"
      click_button "Update"
    end

    assert_text "Setting \"#{Setting::KEYS["scoreboard_visible"][:title]}\" updated successfully."
    assert_equal false, Setting.get("scoreboard_visible")
  end

  test "non-admin cannot access settings page" do
    sign_in @team
    visit settings_path
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path
  end

  test "scoreboard visibility affects home page" do
    # When scoreboard is visible
    Setting.set("scoreboard_visible", "true")
    visit root_path
    assert_selector "h1", text: "Scoreboard"
    assert_selector "table"

    # When scoreboard is not visible
    Setting.set("scoreboard_visible", "false")
    visit root_path
    assert_selector "h1", text: "Scoreboard"
    assert_no_selector "table"
    assert_text "The scoreboard is currently not visible."
  end

  test "scoreboard end time is displayed correctly" do
    end_time = DateTime.new(2024, 9, 27, 14, 0, 0, "+01:00")
    Setting.set("scoreboard_end_time", end_time.to_s)

    visit root_path
    assert_selector "[data-scoreboard-target='timer']", text: /\d+ hours, \d+ minutes, \d+ seconds/
  end
end
