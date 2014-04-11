module UserInputsHelper
  def user_input_type_menu(selected, new_record=false)
    types = UserInput::TYPES.map do |type|
      [UserInput.subtype(type).capitalize, type]
    end
    types.unshift ["Please choose", ""] if new_record
    options_for_select(types, selected)
  end
end
