module RefundsHelper
  def refund_officer_menu(selected)
    user_ids = Refund.pluck("DISTINCT user_id")
    names = User.unscoped.include_player.where(id: user_ids).map { |user| user.player.name }
    officers = names.zip(user_ids).sort { |a,b| a[0] <=> b[0] }
    officers.unshift ["Any Officer", ""]
    options_for_select(officers, selected)
  end
end
