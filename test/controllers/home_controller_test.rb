require "test_helper"

# The polled JSON scoreboard these tests used to cover is gone -- the standings are
# now plain HTML kept fresh by page-refresh broadcasts on the :scoreboard stream, so
# there is no second, separately-gated representation of the same data. Every
# property the JSON tests asserted is re-asserted here against that HTML.
class HomeControllerTest < ActionDispatch::IntegrationTest
  test "the standings are withheld while the scoreboard is hidden" do
    Setting.set("scoreboard_visible", "false")

    get root_path

    assert_response :success
    assert_no_match users(:team_one).name, response.body,
                    "Hidden standings must not be readable by anyone with the URL"
    assert_select "turbo-cable-stream-source", false,
                  "A hidden scoreboard must not subscribe to live updates either"
  end

  test "the standings are served while the scoreboard is visible" do
    Setting.set("scoreboard_visible", "true")

    get root_path

    assert_response :success
    assert_match users(:team_one).name, response.body
    assert_select "turbo-cable-stream-source"
  end

  test "scorers can still read the standings while they are hidden" do
    Setting.set("scoreboard_visible", "false")
    sign_in users(:scorer)

    get root_path

    assert_response :success
    assert_match users(:team_one).name, response.body
  end

  test "scorer-only stats do not leak into the public page via the cache" do
    Setting.set("scoreboard_visible", "true")
    original_cache = Rails.cache
    # The test environment uses a null store, which cannot show cache bleed.
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # A scorer warms the cache with the wider view...
    sign_in users(:scorer)
    get root_path
    assert_select "th", text: "Completed"
    sign_out users(:scorer)

    # ...and a guest must not receive it.
    get root_path

    assert_select "th", { text: "Completed", count: 0 },
                  "Scorer-only completion stats leaked to an anonymous visitor"
  ensure
    Rails.cache = original_cache
  end
end
