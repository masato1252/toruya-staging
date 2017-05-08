module Staffs
  class ReservationDates < ActiveInteraction::Base
    object :shop
    object :staff
    object :date_range, class: Range

    def execute
      shop.reservations.
        joins(:reservation_staffs).
        where("reservation_staffs.staff_id = ?", staff.id).
        where("reservations.start_time" => date_range).uniq("").map{|d| d.start_time.to_date }.uniq
    end
  end
end
