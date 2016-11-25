class Reservations::AvailableOptionsController < DashboardController
  def times
    @time_ranges = shop.available_time(Time.zone.parse(params[:date]).to_date)
  end

  def menus
    @result = Reservations::RetrieveAvailableMenus.run!(shop: shop,
                                                        params: params.permit!.to_h,
                                                        reservation: Reservation.find_by(id: params[:reservation_id]))
  end

  def staffs
    @menu = shop.menus.find(params[:menu_id])
    reservation_time = start_time..end_time

    @staffs = shop.available_staffs(@menu, reservation_time, params[:reservation_id])
  end

  private

  def start_time
    @start_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
  end

  def end_time
    @end_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
  end
end
