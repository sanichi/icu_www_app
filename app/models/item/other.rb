class Item::Other < Item
  def duplicate_of?(item)
    if type == item.type && fee_id == item.fee_id && player_id == item.player_id
      I18n.t("item.error.other.already_in_cart")
    else
      false
    end
  end

  def season
    Season.new(start_date || created_at.to_date)
  end
end
