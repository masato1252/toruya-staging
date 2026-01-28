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
    user_ids += User.business_active.pluck(:id)

    reservations = Reservation.reminderable
                             .where(user_id: user_ids.uniq)
                             .where("start_time >= ? AND start_time <= ?",
                                   date_before_reservation.beginning_of_hour,
                                   date_before_reservation.end_of_hour)

    reservations.find_each do |reservation|
      # 24時間前リマインダーが過去2時間以内に既に送信済みかチェック
      # 各顧客に対してメッセージが送信されているか確認
      already_sent = false
      
      reservation.customers.each do |customer|
        # メール送信履歴をチェック（過去2時間以内）
        sent_message = SocialMessage.where(
          customer_id: customer.id,
          user_id: reservation.user_id,
          channel: 'email',
          message_type: ['bot', 'customer']
        ).where("raw_content LIKE ?", "%#{reservation.start_time.strftime('%Y年%-m月%-d日')}%")
         .where("created_at >= ?", Time.current - 2.hours)
         .exists?

        if sent_message
          already_sent = true
          Rails.logger.info "[Reminder] Skip: reservation_id=#{reservation.id}, customer_id=#{customer.id} - Already sent within 2 hours"
          break
        end
      end

      unless already_sent
        ReservationReminderJob.perform_later(reservation)
      end
    end
  end
end
