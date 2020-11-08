FactoryBot.define do
  factory :reservation_customer do
    association :reservation
    association :customer
    state { :pending }

    trait :pending do
      state { :pending }
    end

    trait :accepted do
      state { :accepted }
    end

    trait :canceled do
      state { :canceled }
    end

    trait :with_new_customer_info do
      details do
        {
          "new_customer_info" => {
            "last_name" => "last_name",
            "first_name" => "first_name",
            "phonetic_last_name" => "phonetic_last_name",
            "phonetic_first_name" => "phonetic_first_name",
            "phone_number" => "phone_number",
            "email" => "email",
            "address_details" => {
              "zip_code" => "zip_code",
              "city" => "city",
              "region" => "region",
              "street1" => "street1",
              "street2" => "street2",
            }
          }
        }
      end
    end
  end
end
