class ReservationsController < DashboardController
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]

  # GET /reservations
  # GET /reservations.json
  def index
    @body_class = "shopIndex"
    @staffs_selector_displaying = true
    @date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    # Calendar START
    # The calendar green cirlce is Working Date is for some staffs
    # The calendar gray cirlce area is Reservations is for this Shop
    date_range = @date.beginning_of_month.beginning_of_day..@date.end_of_month.end_of_day
    @working_dates = Staffs::WorkingDateRules.run!(shop: shop, staff: staff, date_range: date_range)
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, date_range: date_range)
    # Calendar END

    # Staff schedules on date START
    staff_working_schedules_outcome = Shops::StaffsWorkingSchedules.run(shop: shop, date: @date)
    @staffs_working_schedules = staff_working_schedules_outcome.valid? ? staff_working_schedules_outcome.result : []

    time_range_outcome = Reservable::Time.run(shop: shop, date: @date)
    @working_time_range = time_range_outcome.valid? ? time_range_outcome.result : nil
    # Staff schedules on date END

    # Reservations START
    reservations = shop.reservations.uncanceled.in_date(@date).includes(:menu, :customers, :staffs).order("reservations.start_time ASC")
    @schedules = reservations.map do |reservation|
      Option.new(type: :reservation, source: reservation)
    end
    # Reservations END
  end

  # GET /reservations/new
  def new
    @body_class = "resNew"

    @reservation = shop.reservations.new(start_time_date_part: params[:start_time_date_part] || Time.zone.now.to_s(:date),
                                         start_time_time_part: params[:start_time_time_part] || Time.zone.now.to_s(:time),
                                         end_time_time_part: params[:end_time_time_part] || Time.zone.now.advance(hours: 2).to_s(:time),
                                         memo: params[:memo],
                                         menu_id: params[:menu_id],
                                         staff_ids: params[:staff_ids].try(:split, ",").try(:uniq),
                                         customer_ids: params[:customer_ids].try(:split, ",").try(:uniq))

    if current_user.member?
      all_options
    elsif params[:menu_id].present?
      @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, params: params.permit!.to_h)
    end

    if params[:start_time_date_part].present?
      outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:start_time_date_part]).to_date)
      @time_ranges = outcome.valid? ? outcome.result : nil
    end
  end

  # GET /reservations/1/edit
  def edit
    @body_class = "resNew"

    if current_user.member?
      all_options
      @reservation = Reservations::Edit.run!(reservation: @reservation, params: params.permit!.to_h)
    else
      @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, reservation: @reservation, params: params.permit!.to_h)
    end

    outcome = Reservable::Time.run(shop: shop, date: @reservation.start_time.to_date)
    @time_ranges = outcome.valid? ? outcome.result : nil
  end

  def create
    outcome = Reservations::Create.run(shop: shop, params: reservation_params.to_h)

    respond_to do |format|
      if outcome.valid?
        format.html do
          if params[:from_member]
            redirect_to date_member_path(reservation_date: outcome.result.start_time.to_s(:date))
          else
            redirect_to shop_reservations_path(shop, reservation_date: reservation_params[:start_time_date_part]), notice: I18n.t("reservation.create_successfully_message")
          end
        end
      else
        format.html { redirect_to new_shop_reservation_path(shop, reservation_params.to_h), alert: outcome.errors.full_messages.join(", ") }
      end
    end
  end

  def update
    outcome = Reservations::Update.run(shop: shop, reservation: @reservation, params: reservation_params.to_h)

    respond_to do |format|
      if outcome.valid?
        format.html do
          if params[:from_member]
            redirect_to date_member_path(reservation_date: outcome.result.start_time.to_s(:date))
          elsif params[:from_customer_id]
            redirect_to user_customers_path(shop.user, shop_id: params[:shop_id], customer_id: params[:from_customer_id])
          else
            redirect_to shop_reservations_path(shop, reservation_date: reservation_params[:start_time_date_part]), notice: I18n.t("reservation.update_successfully_message")
          end
        end
        format.json { render :show, status: :ok, location: @reservation }
      else
        @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, reservation: @reservation, params: reservation_params.to_h)
        format.html { render :edit }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @reservation.destroy
    if params[:from_member]
      redirect_to member_path, notice: I18n.t("reservation.delete_successfully_message")
    else
      redirect_to shop_reservations_path(shop), notice: I18n.t("reservation.delete_successfully_message")
    end
  end

  def validate
    params[:customer_ids] = if params[:customer_ids].present?
                              params[:customer_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                            else
                              []
                            end

    outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:start_time_date_part]).to_date)
    @time_ranges = outcome.valid? ? outcome.result : nil

    reservation_errors
    if params[:menu_id].presence
      @menu_min_staffs_number = shop.menus.find_by(id: params[:menu_id]).min_staffs_number
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = shop.reservations.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def reservation_params
    params.require(:reservation).permit(:menu_id, :start_time_date_part, :start_time_time_part, :end_time_time_part,
                                        :customer_ids, :staff_ids, :memo, :with_warnings, :by_staff_id)
  end

  def start_time
    @start_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
  end

  def end_time
    @end_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
  end

  def all_options
    menu_options = ShopMenu.includes(:menu).where(shop: shop).map do |shop_menu|
      ::Options::MenuOption.new(id: shop_menu.menu_id, name: shop_menu.menu.display_name,
                                min_staffs_number: shop_menu.menu.min_staffs_number,
                                available_seat: shop_menu.max_seat_number)
    end
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options = shop.staffs.active.order("id").map do |staff|
      ::Options::StaffOption.new(id: staff.id, name: staff.name, handable_customers: nil)
    end
  end

  def reservation_errors
    outcome = Reservable::Reservation.run(
      shop: shop,
      date: Time.zone.parse(params[:start_time_date_part]).to_date,
      business_time_range: start_time..end_time,
      menu_ids: [params[:menu_id].presence].compact.uniq,
      staff_ids: params[:staff_ids].try(:split, ",").try(:uniq) || [],
      reservation_id: params[:reservation_id].presence,
      number_of_customer: (params[:customer_ids].try(:split, ",").try(:flatten).try(:uniq) || []).size
    )

    @errors = outcome.errors.details.each.with_object({}) do |(error_key, error_details), errors|
      error_details.each do |error_detail|
        error_reason = error_detail[:error]
        option = error_detail.tap { |error| error_detail.delete(:error) }

        if error_reason.is_a?(Symbol)
          errors[error_reason] = outcome.errors.full_message(error_key, outcome.errors.generate_message(error_key, error_reason, option))
        elsif error_reason.to_i.is_a?(Integer)
          errors[error_reason] ||= []
          errors[error_reason] << error_key
        else
          errors[error_reason] = outcome.errors.full_message(error_key, error_reason)
        end
      end
    end
  end
end
