class UserInput::Option < UserInput
  def check(item, index)
    # Just mark unchecked options (which correspond to blank notes) for later deletion.
    item.notes[index] = nil unless item.notes[index].present?
  end
end
