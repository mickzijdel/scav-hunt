class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    # Things everyone can do:

    # Things teams can do:
    if user.team?
      can :index, Challenge, group_id: user.visible_groups

      # Teams can read their own scores.
      can :read, Result, user_id: user.id
    end

    # Things scorers can do:
    if user.scorer?
      can :read, Challenge
      can :manage, Result
      can :manage, :scoring
      can :manage, GroupPermission
    end

    # Admins can do everything
    if user.admin?
      can :manage, :all
    end
  end
end
