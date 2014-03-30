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
      can :create, CashPayment
    end

    if user.translator?
      can :manage, Translation
      can :show, JournalEntry, journalable_type: "Translation"
    end

    if user.treasurer?
      can :manage, Fee
      can :index, Item
      can :manage, Cart
      can :index, PaymentError
      can :index, Refund
      can :create, CashPayment
    end

    can :show, Player, id: user.player_id
    can :manage_preferences, User, id: user.id
  end
end
