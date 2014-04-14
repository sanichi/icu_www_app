FactoryGirl.define do
  factory :other_fee, class: Fee::Other do
    active          true
    name            "Something"
    amount          12.34
    player_required false

    factory :donation do
      name   "Donation"
      amount nil
    end

    factory :foreign_rating_fee do
      name            "Foreign Rating"
      amount          10
      player_required true
    end
  end
end
