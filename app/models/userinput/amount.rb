module Userinput
  class Amount < UserInput
    validates :min_amount, presence: true

    def self.extras
      %i[min_amount]
    end

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
          if amount < user_input.min_amount
            error = I18n.t("item.error.user_input.amount.too_small", label: user_input.label, min: user_input.min_amount)
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
