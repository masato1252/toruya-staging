module Notifications
  class PendingCustomerReservationsPresenter < ::NotificationsPresenter
    def data
      oldest_customer_reservation = recent_pending_customer_reservations.first
      oldest_reservation = oldest_customer_reservation&.reservation

      oldest_reservation ? [
        "#{I18n.t("notifications.pending_customer_reservation_need_confirm", number: recent_pending_customer_reservations.count)} #{link_to(I18n.t("notifications.pending_customer_reservation_confirm"), h.user_customers_path(oldest_reservation.shop.user, customer_id: oldest_customer_reservation.customer_id, from_customer_id: oldest_customer_reservation.customer_id, reservation_id: oldest_reservation.id))}"
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
        .order("reservation_customers.created_at ASC")
    end
  end
end
