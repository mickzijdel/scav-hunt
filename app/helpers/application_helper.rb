module ApplicationHelper
  def navbar_items
    navbar_items = [
      { title: "Scoreboard",            path: root_path },
      { title: "Challenges",            path: challenges_path },
      { title: "Users",                 path: users_path }
    ]

    # Display the login link if the user is not signed in yet, otherwise display a link to the admin site and a link to log out.
    if user_signed_in?
      navbar_items << { title: "Log Out", path: destroy_user_session_path, method: :delete, item_class: "border border-white rounded-3" }
    else
      navbar_items << { title: "Log In", path: new_user_session_path, item_class: "border border-white rounded-3" }
    end

    navbar_items
  end
end
