FactoryGirl.define do
  factory :subscripsion_fee, class: Fee::Subscripsion do
    name              "Standard"
    amount            35.0
    years             { Season.new.to_s }
    min_age           nil
    max_age           nil
  end
end
