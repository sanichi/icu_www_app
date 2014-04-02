FactoryGirl.define do
  factory :entry_fee, class: Fee::Entry do
    active     true
    name       "Bunratty Masters"
    amount     50.0
    start_date { Date.today.next_year.beginning_of_year.days_since(35) }
    end_date   { start_date.days_since(2) }
    sale_start { Date.today.days_ago(7) }
    sale_end   { start_date.days_ago(1) }
  end
end
