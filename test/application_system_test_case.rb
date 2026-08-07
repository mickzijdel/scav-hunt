require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Capybara's 2s default is not enough for a Turbo navigation on a loaded
  # machine, which showed up as intermittent "Unable to find field" errors.
  Capybara.default_max_wait_time = 5

  # Capybara's matchers only retry against the DOM. Some of this app's writes
  # happen over fetch/WebSocket with no rendered confirmation, so the only
  # honest thing to wait on is the resulting server-side state.
  def assert_eventually(timeout: 5, message: "condition was never met")
    deadline = Time.current + timeout

    loop do
      break if yield
      flunk "#{message} (waited #{timeout}s)" if Time.current > deadline
      sleep 0.05
    end

    assert true
  end
end
