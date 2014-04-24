module Userinput
  class Date < UserInput
    def self.extras
      %i[required date_constraint]
    end

    def check(item, index)
      note = item.notes[index]
      user_input = item.fee.user_inputs[index]

      if note.present?
        begin
          date = ::Date.parse(note)
          today = ::Date.today
          ok = case user_input.date_constraint
          when "in_the_future"          then date > today
          when "in_the_past"            then date < today
          when "today_or_in_the_future" then date >= today
          when "today_or_in_the_past"   then date <= today
          else true
          end
          if ok
            item.notes[index] = date.to_s
          else
            error = I18n.t("item.error.user_input.date.#{user_input.date_constraint}", label: user_input.label)
          end
        rescue ArgumentError => e
          error = I18n.t("item.error.user_input.date.invalid", label: user_input.label)
        end
      else
        if user_input.required
          error = I18n.t("item.error.user_input.date.missing", label: user_input.label)
        else
          item.notes[index] = nil
        end
      end

      item.errors.add(:base, error) if error
    end
  end
end
