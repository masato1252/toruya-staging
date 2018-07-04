class PendingReservationsSummaryJob < ApplicationJob
  queue_as :default

  def perform(user_id, start_time, end_time)
    start_time = Time.zone.parse(start_time)
    end_time = Time.zone.parse(end_time)
    user = User.find(user_id)

    staff_ids = user.staff_accounts.active.pluck(:staff_id)
    reservations = Reservation.where(aasm_state: :pending, created_at: start_time..end_time).joins(:reservation_staffs).where("reservation_staffs.staff_id": staff_ids, "reservation_staffs.state": ReservationStaff.states[:pending]).to_a

    ReservationMailer.pending_summary(reservations, user).deliver_now
  end
end
