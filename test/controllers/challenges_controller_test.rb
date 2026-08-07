require "test_helper"

class ChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "a valid CSV imports every row and says how many" do
    post_import <<~CSV
      Number,Description,Points,GroupID
      901,Ride the Loch Ness monster,150,4
      902,Recite the alphabet backwards,75,4
    CSV

    assert_redirected_to challenges_path
    assert_equal "Imported 2 challenges.", flash[:notice]
    assert Challenge.exists?(number: 901)
    assert Challenge.exists?(number: 902)
  end

  test "rows rejected by validation are reported instead of silently dropped" do
    # activerecord-import validates by default and skips what fails; the old
    # code discarded that result and reported success regardless.
    assert_difference -> { Challenge.count }, 1 do
      post_import <<~CSV
        Number,Description,Points,GroupID
        903,,150,4
        904,A perfectly good challenge,75,4
      CSV
    end

    assert_response :unprocessable_entity
    assert_match(/1 rejected/, flash[:alert])
    assert_match(/#903/, flash[:alert])
    assert_not Challenge.exists?(number: 903)
    assert Challenge.exists?(number: 904)
  end

  test "a CSV with the wrong headers is rejected rather than importing nothing quietly" do
    assert_no_difference -> { Challenge.count } do
      post_import <<~CSV
        Num,Desc,Pts,Group
        905,Something,100,4
      CSV
    end

    assert_response :unprocessable_entity
    assert_match(/missing required columns/, flash[:alert])
  end

  test "submitting no file is reported" do
    post import_challenges_path

    assert_response :unprocessable_entity
    assert_match(/select a file/, flash[:alert])
  end

  private

  def post_import(csv)
    file = Tempfile.new([ "challenges", ".csv" ])
    file.write(csv)
    file.rewind

    post import_challenges_path,
         params: { import: { file: Rack::Test::UploadedFile.new(file.path, "text/csv") } }
  end
end
