require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with params" do
      # Simulate a connection opening by calling the `connect` method
      user = users(:one)
      cookies.signed["_scav_hunt_session"] = { "warden.user.user.key": [ [ user.id ] ] }
      connect

      # You can access the Connection object via `connection` in tests
      assert_equal connection.current_user, user
    end

    test "rejects connection without params" do
      # Use `assert_reject_connection` matcher to verify that
      # connection is rejected
      assert_reject_connection { connect }
    end
  end
end
