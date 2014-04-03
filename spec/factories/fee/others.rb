FactoryGirl.define do
  factory :other_fee, class: Fee::Other do
    active true
    amount 10.0
    name   "Other"

    factory :trg_fee do
      days 730
    end
  end
end
