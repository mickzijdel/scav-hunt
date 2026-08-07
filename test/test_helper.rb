require "simplecov"
SimpleCov.start

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    #
    # Processes, not threads. Rails turns `lock_threads` off for the threaded
    # executor (ActiveSupport::Testing::ParallelizeExecutor), so every thread shares
    # one pinned, unlocked connection -- and mysql2 segfaults the moment two of them
    # use it at once. The suite never hit this before only because it sat below the
    # 50-test threshold at which parallelization switches on; 60 no-op tests that do
    # nothing but read a fixture reproduce the crash on their own. Each process gets
    # its own database instead, which is both the Rails default and safe here.
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include Devise::Test::IntegrationHelpers
  end
end
