FactoryGirl.define do
  factory :entry_item, class: Item::Entry do
    player
    association :fee, factory: :entry_fee
    status         "unpaid"
    source         "www2"

    factory :paid_entry_item do
      payment_method "stripe"
      status         "paid"
    end
  end
end
