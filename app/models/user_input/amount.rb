class UserInput::Amount < UserInput
  def check(item, index)
    # The item cost should have been set from pre-validation.
    item.errors.add(:base, I18n.t("item.error.user_input.amount")) unless item.cost.present?

    # The note has served it's purpose and can now be marked for deletion.
    item.notes[index] = nil
  end
end
