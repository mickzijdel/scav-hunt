# Cache key for the scoreboard, kept in one place so that the code reading the key
# and the code invalidating it cannot drift apart. Both User and Result invalidate
# on save, and HomeController does the reading.
class Scoreboard
  RANKED_KEY = "teams_ranked".freeze

  # The stream every scoreboard viewer subscribes to. Result broadcasts a page
  # refresh here so each viewer re-renders the standings with their own permissions.
  STREAM = :scoreboard

  def self.clear_cache
    Rails.cache.delete(RANKED_KEY)
  end
end
