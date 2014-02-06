FactoryGirl.define do
  factory :cart do
    status             "unpaid"
    total              nil
    original_total     nil
    payment_method     nil
    payment_ref        nil
    confirmation_email nil
    payment_name       nil
    payment_completed  nil
  end
end
