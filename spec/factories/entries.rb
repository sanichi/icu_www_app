FactoryGirl.define do
  factory :entry do
    player
    entry_fee
    description "Bunratty Masters"
    event_start { Date.today.next_year.beginning_of_year.days_since(35) }
    event_end   { event_start.days_since(2) }
    cost        50.0
    active      true
  end
end
