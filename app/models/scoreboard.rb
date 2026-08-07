# Cache keys for the scoreboard, kept in one place so that the code reading a
# key and the code invalidating it cannot drift apart. Both User and Result
# invalidate on save, and HomeController does the reading.
class Scoreboard
  RANKED_KEY = "teams_ranked".freeze

  # HomeController serves a wider JSON payload to scorers (User#scoreboard_data
  # merges completion stats for them), so the cache is keyed per ability scope.
  # A single shared key meant whoever polled first decided what everyone else
  # received until it expired.
  JSON_SCOPES = %w[scoring public].freeze

  def self.json_key(scope)
    "teams_json/#{scope}"
  end

  def self.clear_cache
    Rails.cache.delete(RANKED_KEY)
    JSON_SCOPES.each { |scope| Rails.cache.delete(json_key(scope)) }
  end
end
