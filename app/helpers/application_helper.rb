module ApplicationHelper
  # Renders the time left until +end_time+ in the same shape the countdown Stimulus
  # controller uses, so the first paint is already correct and the controller only
  # has to keep it ticking.
  def countdown_to(end_time)
    seconds = end_time.nil? ? 0 : (end_time.to_time - Time.current).to_i
    return "Time's up!" if seconds <= 0

    "#{seconds / 1.hour}h #{(seconds / 1.minute) % 60}m #{seconds % 60}s"
  end

  def navbar_items
    navbar_items = [
      { title: "Scoreboard", path: root_path }
    ]

    if can? :index, Challenge
      navbar_items << { title: "Challenges", path: challenges_path }
    end

    if can? :manage, :scoring
      navbar_items << { title: "Scoring", path: scoring_path }
    end

    if can? :manage, GroupPermission
      navbar_items << { title: "Group Permissions", path: group_permissions_path }
    end

    if can? :index, :statistics
      navbar_items << { title: "Statistics", path: statistics_path }
    end

    if can? :index, User
      navbar_items << { title: "Users", path: users_path }
    end

    if can? :manage, Setting
      navbar_items << { title: "Settings", path: settings_path }
    end

    # Display the login link if the user is not signed in yet, otherwise display a link to the admin site and a link to log out.
    if user_signed_in?
      navbar_items << { title: "Log Out", path: destroy_user_session_path, method: :delete, item_class: "border border-white rounded-3" }
    else
      navbar_items << { title: "Log In", path: new_user_session_path, item_class: "border border-white rounded-3" }
    end

    navbar_items
  end
end
