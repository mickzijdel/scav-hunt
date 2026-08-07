class Setting < ApplicationRecord
  validates :key, uniqueness: true
  validates :key, :value, presence: true
  # Mirror the column limits so an over-long value fails as a validation error
  # rather than as a silently truncated (or refused) write at the database.
  validates :key, length: { maximum: 255 }
  validates :value, length: { maximum: 65_535 }

  KEYS = {
    "chart_start_time" => { title: "Chart Start Time", type: :datetime },
    "scoreboard_end_time" => { title: "Scoreboard End Time", type: :datetime },
    "scoreboard_visible" => { title: "Scoreboard Visible", type: :boolean }
  }.freeze

  def self.get(key)
    raise ActiveRecord::RecordNotFound, "Invalid key: #{key}" if KEYS.keys.exclude?(key)

    # If there is a setting, parse it to the correct type. Otherwise, return nil.
    find_by(key: key)&.parsed_value
  end

  # Returns the Setting itself, saved or carrying the errors that stopped it, so a
  # caller can tell a successful write from a rejected one. It used to return the
  # bare boolean from #save, which every caller discarded -- so a blank value was a
  # silent no-op that the settings page still reported as "updated successfully".
  def self.set(key, value)
    raise ActiveRecord::RecordNotFound, "Invalid key: #{key}" if KEYS.keys.exclude?(key)

    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save
    setting
  end

  def parsed_value
    case KEYS.dig(key, :type)
    when :boolean
      value == "true"
    when :datetime
      parsed_time
    else
      value
    end
  end

  private

  # Time.zone.parse, not DateTime.parse. The settings form is free text, so an
  # organiser types a local wall-clock time; DateTime.parse reads a string with no
  # offset as UTC, which is an hour early for the whole of BST -- and this value
  # drives both the countdown clock and the statistics chart window. Time.zone.parse
  # reads it in the application zone and still honours an explicit offset when the
  # string carries one.
  #
  # Returns nil for a string that is not a time at all: this is called straight from
  # view rendering, so a typo must not raise a 500 out of the scoreboard.
  def parsed_time
    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end
