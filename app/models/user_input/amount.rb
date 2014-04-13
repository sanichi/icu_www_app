class UserInput::Amount < UserInput
  def check(item, index)
    # Check the amount.
    error = nil
    if item.notes[index].blank?
      error = "item.error.user_input.amount"
    else
      amount = BigDecimal.new(item.notes[index].to_s.gsub(/[^0-9\.]/, "")).round(2)
      if amount <= Cart::MIN_AMOUNT
        error = "item.error.user_input.amount"
      elsif amount >= Cart::MAX_AMOUNT
        error = "item.error.user_input.amount"
      else
        item.cost = amount
      end
    end

    # Add to base errors if we got one.
    item.errors.add(:base, I18n.t(error)) if error

    # In this case of an amount which sets another item attribute (cost) the note is no longer needed.
    item.notes[index] = nil
  end
end
