FactoryGirl.define do
  factory :cart_item do
    cartable_type nil
    cartable_id   nil
    cart
  end
end
