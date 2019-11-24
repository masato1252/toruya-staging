FactoryBot.define do
  factory :staff_menu do
    association :staff
    association :menu
    max_customers { 2 }
  end
end
