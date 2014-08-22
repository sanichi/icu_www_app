class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.guest?

    if user.roles.present?
      if user.admin?
        can :manage, :all
        return
      end

      if user.editor?
        can :create, [Article, Image, News]
        can [:create, :show], Download
        can [:create, :index, :show], Pgn
        can [:destroy, :update], [Article, Image, News, Pgn, Download], user_id: user.id
        can [:destroy, :update], Game, pgn: { user_id: user.id }
        can :manage, [Champion, Club, Series, Tournament]
      end

      if user.calendar? || user.editor?
        can :create, Event
        can [:destroy, :update], Event, user_id: user.id
      end

      if user.membership?
        can :create, CashPayment
        can :manage, Player
      end

      if user.inspector?
        can :show, Player
      end

      if user.translator?
        can :manage, Translation
        can :show, JournalEntry, journalable_type: "Translation"
      end

      if user.treasurer?
        can :create, CashPayment
        can :index, [Item, PaymentError, Refund]
        can :manage, [Cart, Fee, UserInput]
      end
    end

    can :manage_preferences, User, id: user.id
    can [:manage_profile, :show], Player, id: user.player_id
    can :sales_ledger, Item
  end
end
