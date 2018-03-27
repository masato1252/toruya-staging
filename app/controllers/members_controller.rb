class MembersController < DashboardController
  def show
    @date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date
    all_shop_options = working_shop_options(include_user_own: true)
    @all_shops = all_shop_options.map(&:shop)
    all_staff_ids = all_shop_options.map(&:staff).map(&:id).uniq

    @reservations = Reservation.where(shop_id: @all_shops.map(&:id).uniq).
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

    all_shop_options.each do |option|
      shop = option.shop
      staff = option.staff

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
    @all_shops.each do |shop|
      @reservation_dates += Shops::ReservationDates.run!(shop: shop, date_range: @date.beginning_of_month..@date.end_of_month)
    end

    staffs_off_schedules = CustomSchedule.where(staff_id: all_staff_ids).closed.where("start_time >= ? and end_time <= ?", @date.beginning_of_day, @date.end_of_day).includes(:staff).to_a
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
