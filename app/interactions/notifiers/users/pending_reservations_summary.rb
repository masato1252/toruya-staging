# frozen_string_literal: true

module Notifiers
  module Users
    class PendingReservationsSummary < Base
      deliver_by_priority [:line, :sms, :email]

      time :start_time
      time :end_time

      def message
        reservation_messages = reservations.map do |reservation|
          [
            "#{I18n.l(reservation.start_time, format: :date)} #{I18n.l(reservation.start_time, format: :hour_minute)} 〜 #{I18n.l(reservation.end_time, format: :hour_minute)}" ,
            reservation.shop.display_name,
            I18n.t("notifier.pending_reservations_summary.reservation_by", staff_name: reservation.by_staff&.name, created_at: I18n.l(reservation.created_at))
          ].join("\n")
        end.join("\n\n")

        I18n.t("notifier.pending_reservations_summary.message", user_name: user.name, reservation_messages: reservation_messages)
      end

      def send_email
        ReservationMailer.pending_summary(reservations, user).deliver_now
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
