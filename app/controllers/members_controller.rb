# frozen_string_literal: true

class MembersController < DashboardController
  before_action :set_current_dashboard_mode

  def show
    @date = params[:reservation_date].present? ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    if request.post?
      cookies.clear_across_domains(:member_shops)
      cookies.set_across_domains(:member_shops, params[:member_shops]&.join(",") || "", expires: 20.years.from_now)


      if params[:reservation_date]
        redirect_to date_member_path(reservation_date: @date.to_fs(:date))
        return
      end
    end

    reservations = Reservation.where(shop_id: working_shop_options(include_user_own: true).map(&:shop_id).uniq)
      .uncanceled.in_date(@date)
      .includes(:menus, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # When user responsible for reservation or
    # When user checked the management shops and user is a manager/owner
    # Show the reservations
    reservations = reservations.find_all do |r|
      user_ability = ability(r.shop.user, r.shop)
      user_ability.responsible_for_reservation(r) || (member_shop_ids.include?(r.shop_id.to_s) && user_ability.can?(:see, r))
    end

    # Mix off custom schedules and reservations
    close_schedule_scope = CustomSchedule.closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day)
    off_schedules =
      close_schedule_scope.where(staff_id: working_shop_options(include_user_own: true).map(&:staff_id).uniq).or(
        close_schedule_scope.where(user_id: current_user.id)
    ).to_a

    @schedules = (reservations + off_schedules).each_with_object([]) do |reservation_and_off_schedule, schedules|
      if reservation_and_off_schedule.is_a?(Reservation)
        schedules << Option.new(type: :reservation,
                                source: reservation_and_off_schedule,
                                time: reservation_and_off_schedule.start_time)
      else
        schedules << Option.new(type: :off_schedule,
                                source: reservation_and_off_schedule, # custom_schedules
                                time: reservation_and_off_schedule.start_time,
                                reason: reservation_and_off_schedule.reason.presence || "臨時休暇")
      end
    end.sort_by { |option| option.time }

    notification_presenter = NotificationsPresenter.new(view_context, current_user, params)
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow
  end

  private

  def set_current_dashboard_mode
    cookies.clear_across_domains(:dashboard_mode)
    cookies.set_across_domains(:dashboard_mode, "user", expires: 20.years.from_now)
  end
end
