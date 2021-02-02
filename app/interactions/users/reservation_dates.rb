# frozen_string_literal: true

module Users
  class ReservationDates < ActiveInteraction::Base
    object :user
    # XXX: Avoid the deleted shop cases
    array :all_shop_ids
    object :date_range, class: Range

    def execute
      Reservation.joins(:reservation_staffs)
        .where(shop_id: all_shop_ids)
        .where("reservation_staffs.staff_id" => user.staff_accounts.active.pluck(:staff_id))
        .uncanceled.where("reservations.start_time" => date_range)
        .pluck(:start_time)
        .map{ |start_time| start_time.to_date }
    end
  end
end
