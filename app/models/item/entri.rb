class Item::Entri < Item
  belongs_to :fee, class_name: "Fee::Entri", inverse_of: :items

  validates :start_date, :end_date, presence: true
end
