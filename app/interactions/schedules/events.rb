class Schedules::Events < ActiveInteraction::Base
  array :working_shop_ids do
    integer
  end
  array :user_ids do
    integer
  end
  date :date, default: nil
  date :month_date, default: nil
  date :period_start_date, default: nil
  date :period_end_date, default: nil

  def execute
    # Mix off custom schedules and reservations
    reservations = Reservation.where(shop_id: working_shop_ids)
      .uncanceled
      .includes(:menus, :customers, :staffs, shop: :user, survey_activity: :survey_responses)
      .order("reservations.start_time ASC")
    off_schedules = CustomSchedule.closed.where(user_id: user_ids).includes(user: :profile)
    open_schedules = CustomSchedule.opened.where(user_id: user_ids).includes(user: :profile)
    event_booking_page_ids = BookingPage.where(shop_id: working_shop_ids, event_booking: true).pluck(:id)
    booking_page_holder_schedules = BookingPageSpecialDate.includes(booking_page: :shop).where(booking_page_id: event_booking_page_ids)

    if month_date
      reservations = reservations.in_month(month_date)
      off_schedules = off_schedules.where("start_time <= ? and end_time >= ?", month_date.end_of_month.end_of_day, month_date.beginning_of_month)
      open_schedules = open_schedules.where("start_time <= ? and end_time >= ?", month_date.end_of_month.end_of_day, month_date.beginning_of_month)
      booking_page_holder_schedules = booking_page_holder_schedules.where("start_at >= ? and end_at <= ?", month_date.beginning_of_month, month_date.end_of_month)
    elsif period_start_date && period_end_date
      reservations = reservations.where("start_time <= ? and start_time >= ?", period_end_date.end_of_day, period_start_date.beginning_of_day)
      # show all the off_schedules overlap with the period
      off_schedules = off_schedules.where("start_time <= ? AND end_time >= ?", period_end_date.end_of_day, period_start_date.beginning_of_day)
      # show all the open_schedules overlap with the period
      open_schedules = open_schedules.where("start_time <= ? AND end_time >= ?", period_end_date.end_of_day, period_start_date.beginning_of_day)
      # show all the booking_page_holder_schedules overlap with the period
      booking_page_holder_schedules = booking_page_holder_schedules.where("start_at >= ? and end_at <= ?", period_start_date.end_of_day, period_end_date.beginning_of_day)
    else
      reservations = reservations.where("start_time <= ? and end_time >= ?", date.end_of_day, date.beginning_of_day)
      off_schedules = off_schedules.where("start_time <= ? and end_time >= ?", date.end_of_day, date.beginning_of_day)
      open_schedules = open_schedules.where("start_time <= ? and end_time >= ?", date.end_of_day, date.beginning_of_day)
      booking_page_holder_schedules = booking_page_holder_schedules.where("start_at >= ? and end_at <= ?", date.beginning_of_day, date.end_of_day)
    end

    {
      reservations: reservations,
      booking_page_holder_schedules: booking_page_holder_schedules,
      off_schedules: off_schedules,
      open_schedules: open_schedules
    }
  end
end
