module Shops
  class ReservationDates < ActiveInteraction::Base
    object :shop
    object :date_range, class: Range
  end
end
