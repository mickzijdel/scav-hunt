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
    csv_content = "Number,Description,Points\n1001,New Challenge,200"
    file = Tempfile.new([ "test_import", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_difference("Challenge.count", 1) do
      # Attach the file and submit the form
      attach_file("file", file.path)
      click_on "Import"

      assert_text "Challenges imported successfully"
      assert_selector "td", text: "New Challenge"
    end
  end

  # TODO: Overwriting challenges

  test "exporting challenges" do
    visit challenges_path

    click_on "Export Challenges"

    # Check if the file is downloaded (this might need adjusting based on your testing setup)
    assert_match(/challenges-\d{4}-\d{2}-\d{2}\.csv/, page.response_headers["Content-Disposition"])
  end

  test "non-admin cannot access import/export" do
    sign_out @admin
    sign_in users(:team_one)

    visit import_form_challenges_path
    assert_text "Access denied"
    assert_current_path root_path

    visit export_challenges_path
    assert_text "Access denied"
    assert_current_path root_path
  end
end
