FactoryGirl.define do
  factory :entri_item, class: Item::Entri do
    player
    association :fee, factory: :entri_fee
    description    nil
    cost           nil
    start_date     nil
    end_date       nil
    payment_method nil
    status         "unpaid"
    source         "www2"

    factory :paid_entri_item do
      payment_method "stripe"
      status         "paid"
    end
  end
end
