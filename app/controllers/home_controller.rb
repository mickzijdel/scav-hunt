class HomeController < ApplicationController
  # GET /
  def index
    @title = "Scoreboard"
    # .to_a matters: caching the relation itself stored an unloaded query object,
    # so every "hit" re-ran the query and the cache did nothing.
    @teams = Rails.cache.fetch(Scoreboard::RANKED_KEY, expires_in: 5.minutes) do
      User.teams_ranked.to_a
    end

    @end_time = Setting.get("scoreboard_end_time")
    # Guests and teams only see the standings while the organisers have them switched
    # on. Because the page is refreshed per viewer over the :scoreboard stream, this
    # one check gates the live updates too -- a hidden scoreboard renders (and
    # re-renders) as "not visible", and never subscribes in the first place.
    @scoreboard_visible = can?(:manage, :scoring) || Setting.get("scoreboard_visible")
  end
end
