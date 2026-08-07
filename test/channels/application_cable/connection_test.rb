require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with an authenticated warden session" do
      user = users(:admin)

      # Connection#find_verified_user reads env["warden"], which is populated by
      # Warden::Manager in the real middleware stack. ActionCable's connection
      # TestCase builds a synthetic Rack env and runs no middleware, so the
      # warden proxy has to be supplied directly.
      connect env: { "warden" => Struct.new(:user).new(user) }

      assert_equal user, connection.current_user
    end

    test "rejects connection without params" do
      # Use `assert_reject_connection` matcher to verify that
      # connection is rejected
      assert_reject_connection { connect }
    end
  end
end
