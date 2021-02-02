# frozen_string_literal: true

json.array!(@customers) do |customer|
  json.extract! customer, :id, :shop_id, :customer, :last_name, :first_name, :state
  json.url customer_url(customer, format: :json)
end
