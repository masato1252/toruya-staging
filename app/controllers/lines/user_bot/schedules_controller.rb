# frozen_string_literal: true

class Lines::UserBot::SchedulesController < Lines::UserBotDashboardController
  before_action :back_to_current_user_business

  def index
    @date = params[:reservation_date].present? ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date
    working_shop_ids = working_shop_options(include_user_own: true).map(&:shop_id).uniq
    reservations = Reservation.where(shop_id: working_shop_ids)
      .uncanceled.in_date(@date)
      .includes(:menus, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    reservations = reservations.find_all do |r|
      user_ability = ability(r.shop.user, r.shop)
      user_ability.responsible_for_reservation(r) || (member_shop_ids.include?(r.shop_id.to_s) && user_ability.can?(:see, r))
    end
    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # Mix off custom schedules and reservations
    off_schedules = CustomSchedule.closed.where("start_time <= ? and end_time >= ?", @date.end_of_day, @date.beginning_of_day).where(user_id: current_user.id)
    event_booking_page_ids = BookingPage.where(shop_id: working_shop_ids, event_booking: true).pluck(:id)
    booking_page_holder_schedules = BookingPageSpecialDate.includes(booking_page: :shop).where(booking_page_id: event_booking_page_ids).where("start_at >= ? and end_at <= ?", @date.beginning_of_day, @date.end_of_day)

    @schedules = (reservations + off_schedules + booking_page_holder_schedules).each_with_object([]) do |schedule, schedules|
      if schedule.is_a?(Reservation)
        schedules << ReservationSerializer.new(schedule).attributes_hash
      elsif schedule.is_a?(BookingPageSpecialDate)
        schedules << BookingPageSpecialDateSerializer.new(schedule).attributes_hash
      else
        schedules << OffScheduleSerializer.new(schedule).attributes_hash
      end
    end.sort_by! { |option| option[:time] }

    notification_presenter = NotificationsPresenter.new(view_context, current_user, params)
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow

    if params[:staff_connect_result].present?
      params[:staff_connect_result] == 'true' ? flash.now[:success] = I18n.t("settings.staff_account.staff_connected_successfully") : flash.now[:alert] = I18n.t("settings.staff_account.staff_connected_failed")
    end
  end

  private

  def back_to_current_user_business
    if current_user != super_user
      write_user_bot_cookies(:current_super_user_id, current_user.id)
      redirect_to lines_user_bot_schedules_path(params.permit!.to_h.select { |key, value| key != "controller" && key != "action" })
    end
  end
end
