FactoryGirl.define do
  factory :entri_fee, class: Fee::Entri do
    name              "Bunratty Masters"
    amount            50.0
    start_date        { Date.today.next_year.beginning_of_year.days_since(35) }
    end_date          { start_date.days_since(2) }
    sale_start        { Date.today.days_ago(7) }
    sale_end          { start_date.days_ago(1) }
    discounted_amount nil
    discount_deadline nil
    min_rating        nil
    max_rating        nil
    min_age           nil
    max_age           nil
    age_ref_date      nil
  end
end
