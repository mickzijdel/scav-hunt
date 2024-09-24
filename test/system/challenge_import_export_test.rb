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

      assert_text "Challenges imported successfully"
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

    assert_text "Challenges imported successfully"

    existing_challenge.reload
    assert_not_equal old_description, existing_challenge.description
    assert_equal "Updated Description", existing_challenge.description
    assert_equal 300, existing_challenge.points
  end

  test "exporting challenges" do
    visit challenges_path

    click_on "Export Challenges"

    # Check if the file is downloaded by reporting if it errors (which it will do when it's a csv)
    assert_raise(Capybara::NotSupportedByDriverError) do
      assert_match(/challenges-\d{4}-\d{2}-\d{2}\.csv/, page.response_headers["Content-Disposition"])
    end
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
