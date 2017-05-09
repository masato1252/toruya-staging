class CalendarsController < DashboardController
  def working_schedule
    date = Time.zone.parse(params[:date]).to_date

    @working_dates = Staffs::WorkingDates.run!(shop: shop, staff: shop.staffs.first, date_range: date.beginning_of_month..date.end_of_month)
    @reservation_dates = Staffs::ReservationDates.run!(shop: shop, staff: shop.staffs.first, date_range: date.beginning_of_month..date.end_of_month)
  end
end
