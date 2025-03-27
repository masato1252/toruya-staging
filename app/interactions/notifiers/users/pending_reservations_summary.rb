# frozen_string_literal: true

module Notifiers
  module Users
    class PendingReservationsSummary < Base
      deliver_by_priority [:line]

      time :start_time
      time :end_time

      def message
        I18n.t("notifier.pending_reservations_summary.message", user_name: user.name)
      end

      def deliverable?
        reservations.any?
      end

      private

      def reservations
        @reservations ||=
          begin
            staff_ids = user.staff_accounts.active.pluck(:staff_id)
            reservations = Reservation.active.where(aasm_state: :pending, created_at: start_time..end_time).joins(:reservation_staffs).where("reservation_staffs.staff_id": staff_ids, "reservation_staffs.state": ReservationStaff.states[:pending]).order("id").to_a
          end
      end
    end
  end
end
