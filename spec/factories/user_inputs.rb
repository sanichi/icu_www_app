FactoryGirl.define do
  factory :half_point_bye_option, class: UserInput::Option do
    label "½-point bye in R1"
  end

  factory :donation_amount, class: UserInput::Amount do
    label "Amount to donate"
  end

  factory :comment_text, class: UserInput::Text do
    label      "Comment"
    required   false
    max_length 140
  end

  factory :tournament_text, class: UserInput::Text do
    label      "Tournament name"
    required   true
    max_length 40
  end

  factory :tournament_date, class: UserInput::Mdate do
    label      "Tournament start date"
    required   true
  end
end
