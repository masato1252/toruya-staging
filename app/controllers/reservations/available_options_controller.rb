# frozen_string_literal: true

class Reservations::AvailableOptionsController < DashboardController
  # def times
  #   outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:date]).to_date)
  #   @time_ranges = outcome.valid? ? outcome.result : nil
  # end

  def menus
    @result = Reservations::RetrieveAvailableMenus.run!(shop: shop,
                                                        params: params.permit!.to_h,
                                                        reservation: Reservation.find_by(id: params[:reservation_id]))
  end

  def staffs
    menu = shop.menus.find(params[:menu_id])
    reservation_time = start_time..end_time
    params[:customer_ids] = if params[:customer_ids].present?
                              params[:customer_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                            else
                              []
                            end

    @menu = ::Options::MenuOption.new(id: menu.id, name: menu.name, min_staffs_number: menu.min_staffs_number, online: menu.online)
    @staffs = Reservable::Staffs.run!(shop: shop, menu: menu,
                                      business_time_range: reservation_time,
                                      number_of_customer: params[:customer_ids].size,
                                      reservation_id: params[:reservation_id].presence)
  end

  private

  def start_time
    @start_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
  end

  def end_time
    @end_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
  end
end
