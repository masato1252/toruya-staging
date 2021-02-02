# frozen_string_literal: true

json.array!(@reservations) do |reservation|
  json.extract! reservation, :id, :shop_id, :menu_id, :start_time, :end_time
  json.url reservation_url(reservation, format: :json)
end
