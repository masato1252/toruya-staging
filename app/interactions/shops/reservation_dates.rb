# frozen_string_literal: true

module Shops
  class ReservationDates < ActiveInteraction::Base
    object :shop
    object :date_range, class: Range

    def execute
      shop.reservations.uncanceled.where("reservations.start_time" => date_range).map{ |d| d.start_time.to_date }
    end
  end
end
