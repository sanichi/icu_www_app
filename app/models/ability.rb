class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.guest?

    if user.admin?
      can :manage, :all
      return
    end
    
    if user.editor?
      can :manage, Club
    end
    
    if user.translator?
      can :manage, Translation
    end

    can :manage_preferences, User, id: user.id
  end
end
