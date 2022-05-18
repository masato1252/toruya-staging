# frozen_string_literal: true

FactoryBot.define do
  factory :custom_message do
    service { FactoryBot.create(:online_service) }
    content { "foo" }
    scenario { ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED }
    receiver_ids { [] }

    trait :user_signed_up_scenario do
      service { nil }
      scenario { ::CustomMessages::Users::Template::USER_SIGN_UP }
    end
  end
end
