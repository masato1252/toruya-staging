# frozen_string_literal: true

FactoryBot.define do
  factory :online_service_customer_price do
    amount { Money.new(1000) }
    charge_at { Time.current }
    order_id { OrderId.generate }
  end
end
