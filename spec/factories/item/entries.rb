FactoryGirl.define do
  factory :entry_item, class: Item::Entry do
    player
    association :fee, factory: :entry_fee
    description    nil
    cost           nil
    start_date     nil
    end_date       nil
    payment_method nil
    status         "unpaid"
    source         "www2"

    factory :paid_entry_item do
      payment_method "stripe"
      status         "paid"
    end
  end
end
