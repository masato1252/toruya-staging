FactoryBot.define do
  factory :equipment do
    sequence(:name) { |n| "Equipment #{n}" }
    quantity { 5 }

    association :shop
  end

  factory :menu_equipment do
    required_quantity { 1 }

    association :menu
    association :equipment
  end
end