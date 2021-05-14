# frozen_string_literal: true

module Reservations
  class CheckOut < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.with_lock do
        unless reservation.may_check_out?
          errors.add(:reservation, :not_checkoutable)
          return
        end

        reservation.check_out!

        reservation.customers.each do |customer|
          customer.update(menu_ids: customer.menu_ids.concat(reservation.menu_ids).uniq)
        end
        reservation
      end
    end
  end
end
