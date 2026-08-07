class HomeController < ApplicationController
  def index
    @title = "Scoreboard"
    # .to_a matters: caching the relation itself stored an unloaded query object,
    # so every "hit" re-ran the query and the cache did nothing.
    @teams = Rails.cache.fetch(Scoreboard::RANKED_KEY, expires_in: 5.minutes) do
      User.teams_ranked.to_a
    end

    @end_time = Setting.get("scoreboard_end_time")
    @scoreboard_visible = can?(:manage, :scoring) || Setting.get("scoreboard_visible")

    respond_to do |format|
      format.html
      format.json do
        # The HTML branch hides the scoreboard when the organisers switch it
        # off; the JSON branch used to ignore that entirely, so the standings
        # were readable by anyone with the URL while supposedly hidden.
        if @scoreboard_visible
          render json: teams_json
        else
          head :forbidden
        end
      end
    end
  end

  private

  def teams_json
    # scoreboard_data widens the payload with completion stats for scorers, so
    # the cache key has to vary with that ability -- under a single shared key
    # whoever polled first decided what everyone else received for a minute.
    scope = can?(:manage, :scoring) ? "scoring" : "public"

    Rails.cache.fetch(Scoreboard.json_key(scope), expires_in: 1.minute) do
      @teams.map { |team| team.scoreboard_data(current_ability) }
    end
  end
end
