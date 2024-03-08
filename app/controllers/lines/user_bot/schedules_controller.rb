# frozen_string_literal: true

class Lines::UserBot::SchedulesController < Lines::UserBotDashboardController
  def mine
    @date = params[:reservation_date].present? ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    working_shop_ids = current_social_user.shops.map(&:id).uniq
    reservations = Reservation.where(shop_id: working_shop_ids)
      .uncanceled.in_date(@date)
      .includes(:menus, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    reservations = reservations.find_all do |r|
      user_ability = ability(r.shop.user, r.shop)
      user_ability.responsible_for_reservation(r)
    end
    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # Mix off custom schedules and reservations
    off_schedules = CustomSchedule.closed.where("start_time <= ? and end_time >= ?", @date.end_of_day, @date.beginning_of_day).where(user_id: current_user.id)
    event_booking_page_ids = BookingPage.where(shop_id: working_shop_ids, event_booking: true).pluck(:id)
    booking_page_holder_schedules = BookingPageSpecialDate.includes(booking_page: :shop).where(booking_page_id: event_booking_page_ids).where("start_at >= ? and end_at <= ?", @date.beginning_of_day, @date.end_of_day)

    @schedules = (reservations + booking_page_holder_schedules + off_schedules).each_with_object([]) do |schedule, schedules|
      if schedule.is_a?(Reservation)
        schedules << ReservationSerializer.new(schedule).attributes_hash
      elsif schedule.is_a?(BookingPageSpecialDate)
        schedules << BookingPageSpecialDateSerializer.new(schedule).attributes_hash
      else
        schedules << OffScheduleSerializer.new(schedule).attributes_hash
      end
    end.sort_by! { |option| option[:time] }

    notification_presenter = NotificationsPresenter.new(view_context, Current.user, params.merge(my_calendar: true))
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow

    @my_calendar = true
    render action: :index
  end

  def index
    working_shop_ids = Current.business_owner.shop_ids

    @date =
      if params[:reservation_date].present?
        Time.zone.parse(params[:reservation_date]).to_date
      elsif params[:reservation_id].present?
        Reservation.where(shop_id: working_shop_ids).find(params[:reservation_id]).start_time.to_date
      else
        Time.zone.now.to_date
      end

    reservations = Reservation.where(shop_id: working_shop_ids)
      .uncanceled.in_date(@date)
      .includes(:menus, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # Mix off custom schedules and reservations
    event_booking_page_ids = BookingPage.where(shop_id: working_shop_ids, event_booking: true).pluck(:id)
    booking_page_holder_schedules = BookingPageSpecialDate.includes(booking_page: :shop).where(booking_page_id: event_booking_page_ids).where("start_at >= ? and end_at <= ?", @date.beginning_of_day, @date.end_of_day)

    off_schedules = CustomSchedule.closed.where("start_time <= ? and end_time >= ?", @date.end_of_day, @date.beginning_of_day).where(user_id: Current.business_owner.owner_staff_accounts.pluck(:user_id)).includes(user: :profile)

    @schedules = (reservations + booking_page_holder_schedules + off_schedules).each_with_object([]) do |schedule, schedules|
      if schedule.is_a?(Reservation)
        schedules << ReservationSerializer.new(schedule).attributes_hash
      elsif schedule.is_a?(BookingPageSpecialDate)
        schedules << BookingPageSpecialDateSerializer.new(schedule).attributes_hash
      else
        schedules << OffScheduleSerializer.new(schedule).attributes_hash
      end
    end.sort_by! { |option| option[:time] }

    notification_presenter = NotificationsPresenter.new(view_context, Current.business_owner, params)
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow
  end
end
