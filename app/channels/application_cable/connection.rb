module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    # Anonymous connections are accepted on purpose. The scoreboard is public, and
    # guests have to subscribe to the :scoreboard stream to receive its page-refresh
    # broadcasts -- rejecting them here would leave every signed-out viewer with a
    # frozen scoreboard.
    #
    # Authorisation happens per stream rather than per connection: every
    # subscription runs through Turbo::StreamsChannel, which only accepts a stream
    # name signed with this app's secret, and a signed name is only ever rendered
    # into a page its viewer is allowed to see. A guest therefore holds exactly one
    # name -- :scoreboard -- whose broadcasts carry no data at all, only an
    # instruction to re-request the page, which is then rendered against that
    # viewer's own permissions.
    def connect
      self.current_user = env["warden"]&.user
    end
  end
end
