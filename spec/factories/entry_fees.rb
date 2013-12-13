FactoryGirl.define do
  factory :entry_fee do
    event_name        "Kilkenny Masters"
    amount            50.0
    event_start       "2013-09-22"
    event_end         "2013-09-25"
    sale_start        nil
    sale_end          nil
    discounted_amount nil
    discount_deadline nil
  end
end
