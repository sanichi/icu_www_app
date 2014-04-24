module Userinput
  class Amount < UserInput
    def check(item, index)
      note = item.notes[index].to_s
      user_input = item.fee.user_inputs[index]

      if note.blank?
        error = I18n.t("item.error.user_input.amount.missing", label: user_input.label)
      else
        note = note.gsub(/[^0-9\.]/, "")
        if note.blank?
          error = I18n.t("item.error.user_input.amount.invalid", label: user_input.label)
        else
          amount = BigDecimal.new(note).round(2)
          if amount <= Cart::MIN_AMOUNT
            error = I18n.t("item.error.user_input.amount.too_small", label: user_input.label, min: Cart::MIN_AMOUNT)
          elsif amount >= Cart::MAX_AMOUNT
            error = I18n.t("item.error.user_input.amount.too_large", label: user_input.label, max: Cart::MAX_AMOUNT)
          else
            item.cost = amount
            item.notes[index] = nil
          end
        end
      end

      item.errors.add(:base, error) if error
    end
  end
end
