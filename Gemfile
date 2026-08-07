source "https://rubygems.org", cooldown: 4

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "devise", "~> 4.9", ">= 4.9.4"
gem "cancancan"

gem "simple_form"
gem "csv"
gem "activerecord-import"

gem "redis"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "better_errors"
  gem "factory_bot_rails"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  # Minitest-specific cops. Omakase already bundles (and deliberately disables)
  # rubocop-rails + rubocop-performance, so those are not re-declared here.
  gem "rubocop-minitest", require: false
  # House cops that omakase cannot express, e.g. Mick/ParamsMutation.
  gem "rubocop-mick", github: "mickzijdel/rubocop-mick", require: false

  # --- dev-env standard audit tooling (dev-hooks:dev-env-setup) ---------------
  # All are glob-gated in hk.pkl and mirrored by .github/workflows/ci.yml.
  gem "herb", require: false                   # HTML-aware ERB parser + linter
  gem "bundler-audit", require: false          # gem CVE / insecure-source scan
  gem "debride", require: false                # dead-method detection
  gem "flay", require: false                   # Ruby structural duplication (advisory)
  gem "fasterer", require: false               # performance anti-patterns (advisory)
  gem "database_consistency", require: false   # models vs. schema consistency
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # View test coverage
  gem "simplecov"
  gem "simplecov-rcov"

  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  # Playwright rather than Selenium as the Capybara driver: Playwright's per-action
  # actionability checks (visible / stable / enabled / hit-testable, retried until the
  # timeout) eliminate the silent no-op click that made the suite flaky under Selenium.
  # Rails 7.2 knows `driven_by :playwright` natively — see test/application_system_test_case.rb.
  # Needs the matching `playwright` npm package; the version pairing is pinned in
  # package.json and must be kept in lockstep with Playwright::COMPATIBLE_PLAYWRIGHT_VERSION.
  gem "capybara-playwright-driver"
end
