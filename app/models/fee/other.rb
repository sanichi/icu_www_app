class Fee::Other < Fee
  validates :name, uniqueness: { message: "duplicate" }

  def description(full=false)
    full ? "#{name} Fee" : name
  end

  def applies_to?(user)
    return false unless player_required
    return false unless user.player
    true
  end
end
