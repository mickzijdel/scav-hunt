require "test_helper"
# Rails' driven_by :playwright knows how to build the driver but never requires the gem.
require "capybara-playwright-driver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers

  # Playwright, not Selenium. Under Selenium roughly half of full-suite runs failed with a
  # single Capybara timeout on a different test each time -- always a click that silently did
  # nothing (`click_on "Edit"` leaving the page on the index, `click_on "Create User"` leaving
  # the form un-submitted). Selenium clicks the element's centre coordinate as a one-shot: if
  # the page is still settling, the click lands on nothing and is never retried. Playwright
  # re-checks visible/stable/enabled/hit-testable before every action and retries until the
  # timeout, so a click either lands on the intended element or raises a useful error.
  #
  # Needs the matching `playwright` npm package (pinned exactly in package.json) plus its
  # browser binary: `yarn install && npx playwright install chromium`.
  driven_by :playwright,
    screen_size: [ 1400, 1400 ],
    options: {
      browser_type: :chromium,
      headless: true,
      # Chromium's default /dev/shm is too small for a container/CI sandbox and shows up as
      # random renderer crashes rather than as an obvious out-of-space error.
      args: [ "--disable-dev-shm-usage" ]
    }

  # Required, not cosmetic. The driver's `download` event handler unconditionally does
  # `FileUtils.mkdir_p(Capybara.save_path)`, and Rails never sets Capybara.save_path (its
  # screenshot helper falls back to "tmp/screenshots" on its own). Leaving it nil makes the
  # handler raise inside the Playwright client's event thread the moment a response carries
  # Content-Disposition: attachment, which wedges the connection and hangs the whole run --
  # exactly what the CSV export test triggers. "tmp/screenshots" is also the value Rails'
  # screenshot helper would have defaulted to, so failure screenshots keep their CI path.
  Capybara.save_path = "tmp/screenshots"

  # Capybara's 2s default is not enough for a Turbo navigation on a loaded
  # machine or on CI. Every intermittent failure seen in the full 47-test run
  # was a timeout of this kind ("Unable to find field", "Unable to find modal
  # dialog") on tests that pass consistently in isolation.
  Capybara.default_max_wait_time = 10

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
