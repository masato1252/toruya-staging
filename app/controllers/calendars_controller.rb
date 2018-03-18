class CalendarsController < DashboardController
  def working_schedule
    date = Time.zone.parse(params[:date]).to_date

    @working_dates = Staffs::WorkingDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
  end

  def personal_working_schedule
    date = Time.zone.parse(params[:date]).to_date

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
      working_dates = Staffs::WorkingDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)

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
      @reservation_dates += Shops::ReservationDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
    end

    render action: :working_schedule
  end
end
