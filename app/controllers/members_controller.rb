class MembersController < DashboardController
  def show
    @date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date
    all_shop_options = working_shop_options(include_user_own: true)

    @working_dates, @reservation_dates =  PersonalCalendar.run!(working_shop_options: all_shop_options, date: @date)

    @reservations = Reservation.where(shop_id: all_shop_options.map(&:shop_id).uniq).
      uncanceled.in_date(@date).
      includes(:menu, :customers, :staffs, :shop).
      order("reservations.start_time ASC")

    staffs_off_schedules = CustomSchedule.where(staff_id: all_shop_options.map(&:staff_id).uniq).closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day).includes(:staff).to_a
    existing_reference_ids = []
    @schedules = (@reservations + staffs_off_schedules).each_with_object([]) do |reservation_and_off_schedule, schedules|
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
  end
end
