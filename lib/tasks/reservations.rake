namespace :reservations do
  task :pending_notifications => :environment do
    current_time = Time.now.in_time_zone('Tokyo').beginning_of_hour
    hour = current_time.hour

    if hour == 8 || hour == 20
      time_range = current_time.advance(hours: -12)..current_time.advance(seconds: -1)

      staff_ids = ReservationStaff.pending.joins(:reservation).where("reservations.aasm_state": :pending, "reservations.created_at": time_range).pluck("reservation_staffs.staff_id").uniq
      StaffAccount.active.where(staff_id: staff_ids).distinct.pluck(:user_id).each do |user_id|
        PendingReservationSummaryJob.perform_later(user_id, time_range.first, time_range.last)
      end
    end
  end
end
