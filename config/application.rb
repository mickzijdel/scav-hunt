require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ScavHunt
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # The hunt runs in Edinburgh and the settings form takes free-text local
    # wall-clock times, so the application zone has to be the organisers' zone --
    # left unset it is UTC, and every time typed during BST was an hour out.
    # Timestamps are still stored in UTC (default_timezone is :utc).
    config.time_zone = "Europe/London"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
