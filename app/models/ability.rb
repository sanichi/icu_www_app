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

    if user.membership?
      can :manage, Player
    end

    if user.translator?
      can :manage, Translation
      can :show, JournalEntry, journalable_type: "Translation"
    end

    if user.treasurer?
      can :manage, EntryFee
      can :manage, SubscriptionFee
    end

    can :manage_preferences, User, id: user.id
    can :show, Player, id: user.player_id
  end
end
