FactoryGirl.define do
  factory :other_fee, class: Fee::Other do
    active          true
    name            "Something"
    amount          12.34
    player_required false

    factory :donation do
      name            "Donation"
      amount          nil
    end
  end
end
