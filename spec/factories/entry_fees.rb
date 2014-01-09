FactoryGirl.define do
  factory :entry_fee do
    event_name        "Bunratty Masters"
    amount            50.0
    event_start       { Date.today.next_year.beginning_of_year.days_since(35) }
    event_end         { event_start.days_since(2) }
    sale_start        { Date.today.days_ago(7) }
    sale_end          { event_start.days_ago(1) }
    discounted_amount nil
    discount_deadline nil
    min_rating        nil
    max_rating        nil
    min_age           nil
    max_age           nil
    age_ref_date      nil
  end
end
