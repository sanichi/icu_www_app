class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.guest?

    if user.admin?
      can :manage, :all
      return
    end
    
    can :manage_own_login, User, id: user.id
  end
end
