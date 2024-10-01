class StatisticsService
  def self.points_over_time(time_column)
    new.points_over_time(time_column)
  end

  def points_over_time(time_column)
    start_time = Setting.get("chart_start_time")
    # End time is at most 6 hours after the end of the scav hunt
    end_time = [ Result.order(time_column).last&.send(time_column) || Time.current,  Setting.get("scoreboard_end_time").advance(hours: 6) ].min

    time_intervals = generate_time_intervals(start_time, end_time)

    data = [ [ "timestamps" ] + time_intervals ]

    # Generate each team's point series and add it to the data.
    # The data consists of an array of arrays, the inner array representing the series of points for a team.
    # The first item of the array is the team name.
    User.teams_by_name.includes(:results).each do |team|
      team_data = [ team.name ]

      team_data += time_intervals.map do |interval|
        team.results.where("#{time_column} <= ?", interval)
                    .sum("regular_points + bonus_points")
      end

      data << team_data
    end

    data
  end

  private

  def generate_time_intervals(start_time, end_time)
    intervals = []
    current_time = start_time.change(min: (start_time.min / 30) * 30, sec: 0)

    while current_time <= end_time + 15.minutes
      intervals << current_time
      current_time += 15.minutes
    end

    intervals
  end
end
