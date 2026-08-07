require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "the application zone is the organisers' zone" do
    # Everything below depends on this: the settings form takes a free-text local
    # wall-clock time, so "no offset" has to mean Edinburgh, not UTC.
    assert_equal "Europe/London", Time.zone.name
  end

  test "a datetime with no offset is read in the application zone during BST" do
    Setting.set("scoreboard_end_time", "2024-10-01T15:00:00")

    parsed = Setting.get("scoreboard_end_time")

    assert_equal "+01:00", parsed.formatted_offset
    # 15:00 BST is 14:00 UTC. DateTime.parse used to answer 15:00 UTC -- an hour
    # late on the countdown and on the statistics window.
    assert_equal Time.utc(2024, 10, 1, 14, 0, 0), parsed.utc
  end

  test "a datetime with no offset is read as GMT outside BST" do
    Setting.set("chart_start_time", "2024-12-01T15:00:00")

    assert_equal Time.utc(2024, 12, 1, 15, 0, 0), Setting.get("chart_start_time").utc
  end

  test "an explicit offset in the string is honoured" do
    Setting.set("scoreboard_end_time", "2024-10-01T15:00:00+03:00")

    assert_equal Time.utc(2024, 10, 1, 12, 0, 0), Setting.get("scoreboard_end_time").utc
  end

  test "a value that is not a time reads as unset rather than raising" do
    # parsed_value is called straight out of view rendering, so a typo in the
    # admin form must not take the scoreboard down with it.
    Setting.set("scoreboard_end_time", "half past tea time")
    assert_nil Setting.get("scoreboard_end_time")

    Setting.set("scoreboard_end_time", "2024-13-45T99:00:00")
    assert_nil Setting.get("scoreboard_end_time")
  end

  test "set returns the setting carrying the errors that stopped it" do
    setting = Setting.set("scoreboard_visible", "")

    assert_predicate setting.errors, :any?
    assert_includes setting.errors.full_messages.to_sentence, "Value"
  end

  test "a rejected set leaves the stored value alone" do
    Setting.set("scoreboard_visible", "")

    assert_equal "false", settings(:scoreboard_visible).reload.value
  end

  test "set returns a saved setting when the value is acceptable" do
    setting = Setting.set("scoreboard_visible", "true")

    assert_empty setting.errors
    assert_predicate setting, :persisted?
    assert_equal true, Setting.get("scoreboard_visible")
  end

  test "an unknown key is refused" do
    assert_raises(ActiveRecord::RecordNotFound) { Setting.set("not_a_setting", "1") }
    assert_raises(ActiveRecord::RecordNotFound) { Setting.get("not_a_setting") }
  end

  test "get returns nil for a key that has never been set" do
    assert_nil Setting.get("chart_start_time")
  end
end
