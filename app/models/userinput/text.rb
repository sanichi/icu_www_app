module Userinput
  class Text < UserInput
    validates :max_length, presence: true

    def self.extras
      %i[max_length required]
    end

    def check(item, index)
      note = item.notes[index]
      user_input = item.fee.user_inputs[index]

      if note.present?
        item.notes[index].trim!
      else
        if user_input.required
          item.errors.add(:base, I18n.t("item.error.user_input.text.missing", label: user_input.label))
        else
          item.notes[index] = nil
        end
      end
    end
  end
end
