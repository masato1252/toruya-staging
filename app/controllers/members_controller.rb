class MembersController < DashboardController
  def show
    @date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    # working time in depend on shop
    staff_working_schedules_outcome = Shops::StaffsWorkingSchedules.run(shop: shop, date: @date)
    @staffs_working_schedules = staff_working_schedules_outcome.valid? ? staff_working_schedules_outcome.result : []

    time_range_outcome = Reservable::Time.run(shop: shop, date: @date)
    @working_time_range = time_range_outcome.valid? ? time_range_outcome.result : nil

    # Don't need shops in these
    @reservations = Reservation.where(shop_id: super_user.shop_ids).
      uncanceled.in_date(@date).
      includes(:menu, :customers, :staffs, :shop).
      order("reservations.start_time ASC")

    @working_dates = {
      full_time: false,
      holiday_working: false,
      shop_working_wdays: [],
      staff_working_wdays: [],
      working_dates: [],
      off_dates: [],
      holidays: []
    }

    super_user.shops.each do |shop|
      working_dates = Staffs::WorkingDates.run!(shop: shop, staff: staff, date_range: @date.beginning_of_month..@date.end_of_month)

      @working_dates[:full_time] = @working_dates[:full_time] || working_dates[:full_time]
      @working_dates[:holiday_working] = @working_dates[:holiday_working] || working_dates[:holiday_working]
      @working_dates[:shop_working_wdays] = (@working_dates[:shop_working_wdays] + working_dates[:shop_working_wdays]).uniq
      @working_dates[:staff_working_wdays] = (@working_dates[:staff_working_wdays] + working_dates[:staff_working_wdays]).uniq
      @working_dates[:working_dates] = (@working_dates[:working_dates] + working_dates[:working_dates]).uniq
      @working_dates[:off_dates] = (@working_dates[:off_dates] + working_dates[:off_dates]).uniq
      @working_dates[:holidays] = (@working_dates[:holidays] + working_dates[:holidays]).uniq
    end

    @reservation_dates = []
    super_user.shops.each do |shop|
      @reservation_dates += Shops::ReservationDates.run!(shop: shop, date_range: @date.beginning_of_month..@date.end_of_month)
    end
    @staffs_selector_displaying = true

    staffs_off_schedules = CustomSchedule.where(staff_id: super_user.staff_ids).closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day).includes(:staff).to_a
    @schedules = (@reservations + staffs_off_schedules).map do |reservation_and_off_schedule|
      if reservation_and_off_schedule.is_a?(Reservation)
        Option.new(type: :reservation,
                   source: reservation_and_off_schedule,
                   time: reservation_and_off_schedule.start_time)
      else
        Option.new(type: :off_schedule,
                   source: reservation_and_off_schedule, # custom_schedules
                   time: reservation_and_off_schedule.start_time,
                   reason: reservation_and_off_schedule.reason.presence || "臨時休暇")
      end
    end.sort_by { |option| option.time }
  end
end
