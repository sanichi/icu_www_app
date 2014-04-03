class Fee::Other < Fee
  validates :name, uniqueness: { message: "duplicate" }

  def description(full=false)
    full ? "#{name} Fee" : name
  end
end
