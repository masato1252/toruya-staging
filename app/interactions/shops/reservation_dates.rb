module Shops
  class ReservationDates < ActiveInteraction::Base
    object :shop
    range :date_range
  end
end
