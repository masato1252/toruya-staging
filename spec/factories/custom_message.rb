# frozen_string_literal: true

FactoryBot.define do
  factory :custom_message do
    service { FactoryBot.create(:online_service) }
    content { "%{customer_name} %{shop_name} %{shop_phone_number} %{booking_time} %{meeting_url} %{episode_name} %{episode_end_date} %{lesson_name} %{service_title} %{service_start_date} %{service_end_date}" }
    scenario { ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED }
    receiver_ids { [] }

    trait :user_signed_up_scenario do
      service { nil }
      scenario { ::CustomMessages::Users::Template::USER_SIGN_UP }
    end

    trait :flex do
      content_type { CustomMessage::FLEX_TYPE }
    end
  end
end
