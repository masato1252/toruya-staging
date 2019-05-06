module Booking
  class Calendar < ActiveInteraction::Base
    object :shop
    object :date_range, class: Range

    def execute
      compose(Shops::WorkingCalendar, shop: shop, date_range: date_range)
    end

    private

    def start_date
    end

    def end_date
    end
  end
end
