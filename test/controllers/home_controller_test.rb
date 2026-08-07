require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "the scoreboard JSON is refused while the scoreboard is hidden" do
    Setting.set("scoreboard_visible", "false")

    get home_index_path(format: :json)

    assert_response :forbidden, "Hidden standings must not be readable by anyone with the URL"
  end

  test "the scoreboard JSON is served while the scoreboard is visible" do
    Setting.set("scoreboard_visible", "true")

    get home_index_path(format: :json)

    assert_response :success
  end

  test "scorers can still read the scoreboard JSON while it is hidden" do
    Setting.set("scoreboard_visible", "false")
    sign_in users(:scorer)

    get home_index_path(format: :json)

    assert_response :success
  end

  test "scorer-only stats do not leak into the public payload via the cache" do
    Setting.set("scoreboard_visible", "true")
    original_cache = Rails.cache
    # The test environment uses a null store, which cannot show cache bleed.
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # A scorer warms the cache with the wider payload...
    sign_in users(:scorer)
    get home_index_path(format: :json)
    sign_out users(:scorer)

    # ...and a guest must not receive it.
    get home_index_path(format: :json)

    scorer_only_keys = %w[completed partially_completed not_attempted]
    leaked = JSON.parse(response.body).first.keys & scorer_only_keys

    assert_empty leaked, "Scorer-only completion stats leaked to an anonymous visitor"
  ensure
    Rails.cache = original_cache
  end
end
