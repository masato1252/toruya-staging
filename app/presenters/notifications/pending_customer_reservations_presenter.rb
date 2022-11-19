# frozen_string_literal: true

module Notifications
  class PendingCustomerReservationsPresenter < ::NotificationsPresenter
    def data
      oldest_customer_reservation = recent_pending_customer_reservations.first
      oldest_reservation = oldest_customer_reservation&.reservation

      oldest_reservation ? [
        "#{I18n.t("notifications.pending_customer_reservation_need_confirm", number: recent_pending_customer_reservations.count)} #{link_to(I18n.t("notifications.pending_customer_reservation_confirm"), SiteRouting.new(h).reservation_form_path(oldest_reservation))}"
      ] : []
    end

    private

    def recent_pending_customer_reservations
      ReservationCustomer
        .pending
        .joins("inner join customers on customers.id = reservation_customers.customer_id")
        .includes(reservation: [:shop, :reservation_staffs])
        .where("reservation_staffs.staff_id": staff_ids)
        .where("customers.deleted_at": nil)
        .where("reservations.deleted_at": nil)
        .where("reservations.start_time > ?", 1.day.ago)
        .order("reservation_customers.created_at ASC")
    end
  end
end
