class Item::Subscripsion < Item
  belongs_to :fee, class_name: "Fee::Subscripsion", inverse_of: :items

  validates :start_date, :end_date, presence: true
end
