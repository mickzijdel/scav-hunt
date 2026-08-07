require "application_system_test_case"

class ChallengeImportExportTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    sign_in @admin
  end

  test "importing challenges" do
    visit challenges_path

    click_on "Import Challenges"

    # Prepare a test CSV file
    csv_content = "Number,GroupID,Description,Points\n1001,1,New Challenge,200\n1002,1,Another Challenge,200"
    file = Tempfile.new([ "test_import", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_difference("Challenge.count", 2) do
      # Attach the file and submit the form
      attach_file("file", file.path)
      click_on "Import"

      assert_text "Imported 2 challenges."
      assert_selector "a", text: "New Challenge"
    end
  end
  test "overwriting existing challenges" do
    existing_challenge = challenges(:one)
    old_description = existing_challenge.description

    # Prepare a test CSV file with updated data
    csv_content = "Number,GroupID,Description,Points\n#{existing_challenge.number},1,Updated Description,300"
    file = Tempfile.new([ "test_import", ".csv" ])
    file.write(csv_content)
    file.rewind

    visit challenges_path
    click_on "Import Challenges"

    attach_file("file", file.path)
    click_on "Import"

    assert_text "Imported 1 challenge."

    existing_challenge.reload
    assert_not_equal old_description, existing_challenge.description
    assert_equal "Updated Description", existing_challenge.description
    assert_equal 300, existing_challenge.points
  end

  test "exporting challenges" do
    # Selenium exposed nothing about a download, so this test used to assert only that
    # Capybara raised NotSupportedByDriverError -- it tested the driver's limitation, not
    # the app. Playwright saves downloads under Capybara.save_path (on a background
    # thread), so assert what the export actually produces.
    export_glob = Rails.root.join(Capybara.save_path, "challenges-*.csv").to_s
    FileUtils.rm_f(Dir.glob(export_glob))

    visit challenges_path

    click_on "Export Challenges"

    downloaded = nil
    assert_eventually(timeout: 10, message: "the challenges CSV was never downloaded") do
      downloaded = Dir.glob(export_glob).first
    end

    assert_equal "challenges-#{Date.today}.csv", File.basename(downloaded)
  end

  test "non-admin cannot access import/export" do
    sign_out @admin
    sign_in users(:team_one)

    visit import_form_challenges_path
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path

    visit export_challenges_path
    assert_text "I'm sorry, I can't let you do that"
    assert_current_path root_path
  end
end
