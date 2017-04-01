class CalendarsController < DashboardController
  def holidays
    date = Time.zone.parse(params[:date]).to_date
    holidays = Holidays.between(date.beginning_of_month, date.end_of_month)
    @holiday_days = holidays.map { |holiday| holiday[:date].day }
  end
end
