FactoryGirl.define do
  factory :half_point_bye_option, class: UserInput::Option do
    label "½-point bye in R1"
  end

  factory :donation_amount, class: UserInput::Amount do
    label "Amount to donate"
  end
end
