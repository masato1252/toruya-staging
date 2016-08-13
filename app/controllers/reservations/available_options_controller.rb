class Reservations::AvailableOptionsController < DashboardController
  def times
    @time_ranges = shop.available_time(Time.zone.parse(params[:date]).to_date)
  end

  def menus
    @menus = shop.available_reservation_menus(start_time..end_time)

    @staffs = if @menus.present?
      @selected_menu = @menus.first
      shop.available_staffs(@selected_menu, start_time..end_time)
    end
  end

  def staffs
    @menu = shop.menus.find(params[:menu_id])
    @staffs = shop.available_staffs(@menu, start_time..end_time)
  end

  def customers
  end

  private

  def start_time
    @start_time ||= Time.zone.parse("#{params[:date]}-#{params[:start_time_time_part]}")
  end

  def end_time
    @end_time ||= Time.zone.parse("#{params[:date]}-#{params[:end_time]}")
  end
end
