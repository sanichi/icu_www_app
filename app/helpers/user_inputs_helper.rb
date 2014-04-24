module UserInputsHelper
  def user_input_type_menu(selected, new_record=false)
    types = UserInput::TYPES.map do |type|
      [UserInput.subtype(type).capitalize, type]
    end
    types.unshift ["Please choose", ""] if new_record
    options_for_select(types, selected)
  end

  def user_input_date_constraint_menu(selected)
    constraints = UserInput::DATE_CONSTRAINTS.map do |constraint|
      [constraint.humanize, constraint]
    end
    options_for_select(constraints, selected)
  end
end
