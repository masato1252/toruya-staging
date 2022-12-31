# frozen_string_literal: true

class Lines::UserBot::SchedulesController < Lines::UserBotDashboardController
  def index
    @date = params[:reservation_date].present? ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    reservations = Reservation.where(shop_id: working_shop_options(include_user_own: true).map(&:shop_id).uniq)
      .uncanceled.in_date(@date)
      .includes(:menus, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    reservations = reservations.find_all do |r|
      user_ability = ability(r.shop.user, r.shop)
      user_ability.responsible_for_reservation(r) || (member_shop_ids.include?(r.shop_id.to_s) && user_ability.can?(:see, r))
    end

    # Mix off custom schedules and reservations
    off_schedules = CustomSchedule.closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day).where(user_id: current_user.id)

    @schedules = (reservations + off_schedules).each_with_object([]) do |reservation_and_off_schedule, schedules|
      if reservation_and_off_schedule.is_a?(Reservation)
        schedules << ReservationSerializer.new(reservation_and_off_schedule).attributes_hash
      else
        schedules << OffScheduleSerializer.new(reservation_and_off_schedule).attributes_hash
      end
    end.sort_by! { |option| option[:time] }

    notification_presenter = NotificationsPresenter.new(view_context, current_user, params)
    @notification_messages = notification_presenter.data
    @reservations_approvement_flow = notification_presenter.reservations_approvement_flow

    if params[:staff_connect_result].present?
      params[:staff_connect_result] == 'true' ? flash.now[:success] = "Successful" : flash.now[:alert] = "Connected failed"
    end
  end
end
