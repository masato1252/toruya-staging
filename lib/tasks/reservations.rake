# frozen_string_literal: true

namespace :reservations do
  # notify pending reservations summary to reservation's responsible staff
  task :pending_notifications => :environment do
    current_time = Time.current.beginning_of_hour
    hour = current_time.hour

    if hour == 8 || hour == 20
      time_range = current_time.advance(hours: -12)..current_time.advance(seconds: -1)

      staff_ids = ReservationStaff.pending.joins(:reservation).where("reservations.aasm_state": :pending, "reservations.created_at": time_range, "reservations.deleted_at": nil).pluck("reservation_staffs.staff_id").uniq
      business_owner_ids = StaffAccount.active.where(staff_id: staff_ids).distinct.pluck(:owner_id).uniq
      staff_user_ids = StaffAccount.active.where(owner_id: business_owner_ids).pluck(:user_id).uniq

      staff_user_ids.each do |user_id|
        PendingReservationsSummaryJob.perform_later(user_id, time_range.first.to_s, time_range.last.to_s)
      end
    end
  end

  # run hourly
  # reminder customer
  task :reminder => :environment do
    date_before_reservation = Time.current.advance(hours: 24)

    user_ids = Subscription.charge_required.pluck(:user_id) + Subscription.where("trial_expired_date > ?", Time.current).pluck(:user_id)

    reservations = Reservation.reminderable
                             .where(user_id: user_ids)
                             .where("start_time >= ? AND start_time <= ?",
                                   date_before_reservation.beginning_of_hour,
                                   date_before_reservation.end_of_hour)

    reservations.find_each do |reservation|
      ReservationReminderJob.perform_later(reservation)
    end
  end
end
