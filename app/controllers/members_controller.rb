class MembersController < DashboardController
  def show
    @date = params[:reservation_date].present? ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    if request.post?
      cookies[:member_shops] = params[:member_shops]&.join(",") || ""

      if params[:reservation_date]
        redirect_to date_member_path(reservation_date: @date.to_s(:date))
        return
      end
    end

    # XXX: CalendarsController#personal_working_schedule use the same PersonalCalendar, be careful
    @working_dates, @reservation_dates = PersonalCalendar.run!(
      user: current_user,
      working_shop_options: member_shops_options,
      all_shop_ids: working_shop_options(include_user_own: true).map(&:shop_id).uniq,
      date: @date
    )

    reservations = Reservation.where(shop_id: working_shop_options(include_user_own: true).map(&:shop_id).uniq)
      .uncanceled.in_date(@date)
      .includes(:menu, :customers, :staffs, shop: :user)
      .order("reservations.start_time ASC")

    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # When user responsible for reservation or
    # When user checked the management shops and user is a manager/owner
    # Show the reservations
    reservations = reservations.find_all do |r|
      user_ability = ability(r.shop.user)
      user_ability.responsible_for_reservation(r) || (member_shop_ids.include?(r.shop_id.to_s) && user_ability.can?(:see, r))
    end

    # Mix off custom schedules and reservations
    staffs_off_schedules = CustomSchedule
      .where(staff_id: working_shop_options(include_user_own: true).map(&:staff_id).uniq)
      .closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day)
      .includes(:staff).to_a

    existing_reference_ids = []

    @schedules = (reservations + staffs_off_schedules).each_with_object([]) do |reservation_and_off_schedule, schedules|
      if reservation_and_off_schedule.is_a?(Reservation)
        schedules << Option.new(type: :reservation,
                                source: reservation_and_off_schedule,
                                time: reservation_and_off_schedule.start_time)
      else
        next if existing_reference_ids.include?(reservation_and_off_schedule.reference_id)
        existing_reference_ids << reservation_and_off_schedule.reference_id if reservation_and_off_schedule.reference_id

        schedules << Option.new(type: :off_schedule,
                                source: reservation_and_off_schedule, # custom_schedules
                                time: reservation_and_off_schedule.start_time,
                                reason: reservation_and_off_schedule.reason.presence || "臨時休暇")
      end
    end.sort_by { |option| option.time }

    @notification_messages = NotificationsPresenter.new(view_context, current_user).data
  end
end
