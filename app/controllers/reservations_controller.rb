class ReservationsController < DashboardController
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]
  before_action :set_current_dashboard_mode, only: %i(index)
  before_action :repair_nested_params, only: [:create, :update, :validate]

  def show
    @sentences = view_context.reservation_staff_sentences(@reservation)
    render layout: false
  end

  # GET /reservations
  # GET /reservations.json
  def index
    authorize! :read, :shop_dashboard
    @body_class = "shopIndex"
    @staffs_selector_displaying = true
    @date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    # Staff schedules on date START
    staff_working_schedules_outcome = Shops::StaffsWorkingSchedules.run(shop: shop, date: @date)
    @staffs_working_schedules = staff_working_schedules_outcome.valid? ? staff_working_schedules_outcome.result : []
    # Staff schedules on date END

    # Reservations START
    reservations = shop.reservations.uncanceled.in_date(@date).includes(:shop, :menus, :customers, :staffs).order("reservations.start_time ASC")
    @schedules = reservations.map do |reservation|
      Option.new(type: :reservation, source: reservation)
    end
    # Reservations END

    # Notifications START
    @empty_reservation_setting_user_message = Notifications::EmptyReservationSettingUserPresenter.new(view_context, current_user).data(staff_account: current_user_staff_account)
    @empty_menu_shop_message = Notifications::EmptyMenuShopPresenter.new(view_context, current_user).data(owner: super_user, shop: shop, in_shop_dashboard: true)
    @notification_messages = [@empty_reservation_setting_user_message, @empty_menu_shop_message].compact
    # Notifications END
  end

  # GET /reservations/new
  def new
    authorize! :create_reservation, shop
    authorize! :manage_shop_reservations, shop
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

  def form
    @body_class = "resNew"

    @reservation = shop.reservations.find_by(id: params[:id])
    @reservation ||= shop.reservations.new(
      start_time_date_part: params[:start_time_date_part] || Time.zone.now.to_s(:date),
      start_time_time_part: params[:start_time_time_part] || Time.zone.now.to_s(:time),
      end_time_date_part: params[:end_time_date_part] || params[:start_time_date_part] || Time.zone.now.to_s(:date),
      end_time_time_part: params[:end_time_time_part] || Time.zone.now.advance(hours: 2).to_s(:time),
      memo: params[:memo],
      menu_id: params[:menu_id],
      staff_ids: params[:staff_ids].try(:split, ",").try(:uniq),
      customer_ids: params[:customer_ids].try(:split, ",").try(:uniq)
    )

    all_options
    if params[:start_time_date_part].present?
      outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:start_time_date_part]).to_date)
      @time_ranges = outcome.valid? ? outcome.result : nil
    end
  end

  # GET /reservations/1/edit
  def edit
    authorize! :manage_shop_reservations, shop
    authorize! :edit, @reservation

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
    # sleep 3
    # redirect_to form_shop_reservations_path(shop)
    # return

    authorize! :create_reservation, shop
    authorize! :manage_shop_reservations, shop

    outcome = Reservations::Save.run(reservation: shop.reservations.new, params: reservation_params_hash)

    respond_to do |format|
      if outcome.valid?
        format.html do
          if in_personal_dashboard?
            redirect_to date_member_path(reservation_date: outcome.result.start_time.to_s(:date))
          else
            redirect_to shop_reservations_path(shop, reservation_date: reservation_params_hash[:start_time_date_part]), notice: I18n.t("reservation.create_successfully_message")
          end
        end
      else
        format.html { redirect_to new_shop_reservation_path(shop, reservation_params_hash.to_h), alert: outcome.errors.full_messages.join(", ") }
      end
    end
  end

  def update
    authorize! :manage_shop_reservations, shop
    authorize! :edit, @reservation
    outcome = Reservations::Save.run(reservation: @reservation, params: reservation_params_hash)

    if outcome.valid?
      if params[:from_customer_id].present?
        redirect_to user_customers_path(shop.user, shop_id: params[:shop_id], customer_id: params[:from_customer_id])
      elsif in_personal_dashboard?
        redirect_to date_member_path(reservation_date: outcome.result.start_time.to_s(:date))
      else
        redirect_to shop_reservations_path(shop, reservation_date: reservation_params_hash[:start_time_date_part]), notice: I18n.t("reservation.update_successfully_message")
      end
    else
      # TODO: Handle failure case
      all_options
      render "form"
    end
  end

  def destroy
    authorize! :edit, @reservation

    Reservations::Delete.run!(reservation: @reservation)

    if params[:from_customer_id].present?
      redirect_to user_customers_path(shop.user, shop_id: params[:shop_id], customer_id: params[:from_customer_id])
    elsif in_personal_dashboard?
      redirect_to member_path, notice: I18n.t("reservation.delete_successfully_message")
    else
      redirect_to shop_reservations_path(shop), notice: I18n.t("reservation.delete_successfully_message")
    end
  end

  def validate
    outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:reservation_form][:start_time_date_part]).to_date)
    @time_ranges = outcome.valid? ? outcome.result : nil

    @customer_max_load_capability = reservation_params_hash[:menu_staffs_list].map do |menu_staffs_list|
      staff_ids = menu_staffs_list[:staff_ids].map { |hh| hh[:staff_id] }.compact
      return 0 if staff_ids.blank?

      Reservable::CalculateCapabilityForCustomers.run!(
        shop: shop,
        menu_id: menu_staffs_list[:menu_id],
        staff_ids: staff_ids
      )
    end.min

    reservation_errors
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = shop.reservations.find(params[:id])
  end

  # def start_time
  #   @start_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
  # end
  #
  # def end_time
  #   @end_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
  # end

  def all_options
    menu_options = ShopMenu.includes(:menu).where(shop: shop).map do |shop_menu|
      ::Options::MenuOption.new(
        id: shop_menu.menu_id,
        name: shop_menu.menu.display_name,
        min_staffs_number: shop_menu.menu.min_staffs_number,
        available_seat: shop_menu.max_seat_number,
        minutes: shop_menu.menu.minutes,
        interval: shop_menu.menu.interval
      )
    end
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options =
      if super_user.premium_member?
        shop.staffs.order("id").map do |staff|
          ::Option.new(id: staff.id, name: staff.name, handable_customers: nil)
        end
      else
        [
          ::Option.new(id: current_user_staff.id, name: current_user_staff.name, handable_customers: nil)
        ]
      end
  end

  def reservation_errors
    outcome = Reservations::Validate.run(
      reservation: @reservation || shop.reservations.new,
      params: reservation_params_hash
    )

    @errors_with_warnings = outcome.result
  end

  def set_current_dashboard_mode
    cookies[:dashboard_mode] = shop.id
  end

  def reservation_params_hash
    return @reservation_params_hash if defined?(@reservation_params_hash)

    @reservation_params_hash = params.permit!.to_h["reservation_form"]

    if @reservation_params_hash[:start_time_date_part] && @reservation_params_hash[:start_time_time_part]
      @reservation_params_hash[:start_time] = Time.zone.parse("#{@reservation_params_hash[:start_time_date_part]}-#{@reservation_params_hash[:start_time_time_part]}")
    end

    if @reservation_params_hash[:start_time_date_part] && @reservation_params_hash[:end_time_time_part]
      @reservation_params_hash[:end_time] = Time.zone.parse("#{@reservation_params_hash[:start_time_date_part]}-#{@reservation_params_hash[:end_time_time_part]}")
    end

    @reservation_params_hash["menu_staffs_list"].delete_if {|hh| hh["menu_id"].blank? } if @reservation_params_hash["menu_staffs_list"]
    @reservation_params_hash
  end
end
