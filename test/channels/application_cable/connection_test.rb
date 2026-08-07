require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with an authenticated warden session" do
      user = users(:admin)

      # Connection#connect reads env["warden"], which is populated by
      # Warden::Manager in the real middleware stack. ActionCable's connection
      # TestCase builds a synthetic Rack env and runs no middleware, so the
      # warden proxy has to be supplied directly.
      connect env: { "warden" => Struct.new(:user).new(user) }

      assert_equal user, connection.current_user
    end

    test "connects anonymously so signed-out visitors can watch the public scoreboard" do
      connect

      assert_nil connection.current_user,
                 "A guest connection must be accepted, but must not be identified as anyone"
    end
  end
end
