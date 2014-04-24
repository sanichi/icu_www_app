module Userinput
  class Date < UserInput
    def self.extras
      %i[required]
    end

    def check(item, index)
      note = item.notes[index]
      user_input = item.fee.user_inputs[index]

      if note.present?
        begin
          date = ::Date.parse(note)
          item.notes[index] = date.to_s
        rescue
          error = I18n.t("item.error.user_input.mdate.invalid", label: user_input.label)
        end
      else
        if user_input.required
          error = I18n.t("item.error.user_input.mdate.missing", label: user_input.label)
        else
          item.notes[index] = nil
        end
      end

      item.errors.add(:base, error) if error
    end
  end
end
