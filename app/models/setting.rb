class Setting < ApplicationRecord
  validates :key, uniqueness: true
  validates :key, :value, presence: true

  KEYS = {
    "scoreboard_end_time" => { title: "Scoreboard End Time", type: :datetime },
    "scoreboard_visible" => { title: "Scoreboard Visible", type: :boolean }
  }.freeze

  def self.get(key)
    raise ActiveRecord::RecordNotFound, "Invalid key: #{key}" if KEYS.keys.exclude?(key)

    setting = find_by(key: key)


    # If there is a setting, parse it to the correct type. Otherwise, return nil.
    if setting
      setting.parsed_value
    else
      nil
    end
  end

  def self.set(key, value)
    raise ActiveRecord::RecordNotFound, "Invalid key: #{key}" if KEYS.keys.exclude?(key)

    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save
  end

  def parsed_value
    case KEYS.dig(key, :type)
    when :boolean
      value == "true"
    when :datetime
      DateTime.parse(value)
    else
      value
    end
  end
end
