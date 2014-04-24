FactoryGirl.define do
  factory :half_point_bye_option, class: Userinput::Option do
    label "½-point bye in R1"
  end

  factory :donation_amount, class: Userinput::Amount do
    label      "Amount to donate"
    min_amount 1.0
  end

  factory :comment_text, class: Userinput::Text do
    label      "Comment"
    required   false
    max_length 140
  end

  factory :tournament_text, class: Userinput::Text do
    label      "Tournament name"
    required   true
    max_length 40
  end

  factory :tournament_date, class: Userinput::Date do
    label      "Tournament start date"
    required   true
  end
end
