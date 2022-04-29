# frozen_string_literal: true

FactoryBot.define do
  factory :custom_message do
    service { FactoryBot.create(:online_service) }
    content { "foo" }
    scenario { ::CustomMessages::Template::ONLINE_SERVICE_PURCHASED }
    receiver_ids { [] }
  end
end
