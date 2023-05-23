# frozen_string_literal: true

class ReservationSerializer
  include JSONAPI::Serializer

  # TODO: Form bug, it won't send with_warnings https://github.com/ilake/kasaike/commit/bc56b28579e6e74a04cc746c0253c18699f27361
  attributes :id, :with_warnings, :shop

  attribute :state, &:aasm_state

  attribute :type do
    :reservation
  end

  attribute :customer_names_sentence do |reservation|
    ApplicationController.helpers.customer_names_sentence(reservation)
  end

  attribute :sentences do |reservation|
    ApplicationController.helpers.reservation_staff_sentences(reservation)
  end

  attribute :start_time do |reservation|
    reservation.start_time.to_fs(:time)
  end

  attribute :end_time do |reservation|
    reservation.end_time.to_fs(:time)
  end

  attribute :time do |reservation|
    reservation.start_time
  end

  attribute :menus_name do |reservation|
    reservation.menus.map(&:display_name).join(", ")
  end

  attribute :shop_name do |reservation|
    reservation.shop.display_name
  end
end
