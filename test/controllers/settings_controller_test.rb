require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the index offers a form for every key, including ones never set" do
    get settings_path

    assert_response :success
    Setting::KEYS.each_key do |key|
      assert_select "form##{"settings_form_#{key}"}"
    end
  end

  test "rendering the index persists nothing" do
    # It used to call find_or_create_by, so every render fired an INSERT for each
    # unset key that could only ever fail validation.
    assert_no_difference -> { Setting.count } do
      get settings_path
    end
  end

  test "a valid update is saved and reported" do
    patch settings_path, params: { setting: { key: "scoreboard_visible", value: "true" } }

    assert_redirected_to settings_path
    assert_match(/updated successfully/, flash[:notice])
    assert_equal "true", settings(:scoreboard_visible).reload.value
  end

  test "a blank value is refused instead of being reported as a success" do
    patch settings_path, params: { setting: { key: "scoreboard_end_time", value: "" } }

    assert_response :unprocessable_entity
    assert_nil flash[:notice]
    assert_equal "2024-09-28T14:00:00+01:00", settings(:scoreboard_end_time).reload.value
  end

  test "a refused update comes back with the error on the form" do
    patch settings_path, params: { setting: { key: "scoreboard_end_time", value: "" } }

    assert_select "form#settings_form_scoreboard_end_time" do
      assert_select ".invalid-feedback", text: /can't be blank/
    end
  end

  test "a non-admin cannot update a setting" do
    sign_in users(:team_one)

    patch settings_path, params: { setting: { key: "scoreboard_visible", value: "true" } }

    assert_redirected_to root_path
    assert_equal "false", settings(:scoreboard_visible).reload.value
  end
end
