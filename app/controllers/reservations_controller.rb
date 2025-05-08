# frozen_string_literal: true

class ReservationsController < DashboardController
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]
  before_action :set_current_dashboard_mode, only: %i(index)
  before_action :repair_nested_params, only: [:create, :update, :validate, :add_customer]

  def show
    @sentences = view_context.reservation_staff_sentences(@reservation)
    @shop_user = @reservation.shop.user
    @user_ability = ability(@shop_user, @reservation.shop)
    @customer = Customer.find_by(id: params[:from_customer_id])
    @reservation_customer = ReservationCustomer.find_by(reservation_id: @reservation.id, customer_id: params[:from_customer_id])

    render action: params[:from_customer_id] ? "customer_reservation_show" : "show", layout: false
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
    @reservation = reservations.find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    # Reservations END

    # Notifications START
    @empty_reservation_setting_user_message = Notifications::EmptyReservationSettingUserPresenter.new(view_context, current_user).data(staff_account: current_user_staff_account)
    @notification_messages = [@empty_reservation_setting_user_message].compact
    # Notifications END
  end

  def form
    @body_class = "resNew"
    all_options

    if Rails.cache.read(reservation_params_hash_cache_key) && params[:from_adding_customer]
      reservarion_params = JSON.parse(Rails.cache.read(reservation_params_hash_cache_key)).with_indifferent_access
      menu_staffs_list = reservarion_params.delete(:menu_staffs_list)
      customers_list = reservarion_params.delete(:customers_list)
      reservation_id = reservarion_params.delete(:reservation_id)
      staff_states = reservarion_params.delete(:staff_states)

      @reservation = shop.reservations.find_or_initialize_by(id: reservation_id)
      @reservation.attributes = reservarion_params
      @menu_staffs_list = menu_staffs_list
      @staff_states = staff_states.presence || []
      @customers_list = Array.wrap(customers_list).map {|h| h.merge!(details: h[:details]&.to_json ) }
    else
      @reservation = shop.reservations.find_by(id: params[:id])
      @reservation ||= shop.reservations.new(
        start_time_date_part: params[:start_time_date_part] || Time.zone.now.to_fs(:date),
        start_time_time_part: Time.zone.now.to_fs(:time),
        end_time_date_part: params[:start_time_date_part] || Time.zone.now.to_fs(:date),
        end_time_time_part: Time.zone.now.advance(hours: 2).to_fs(:time),
      )
      @menu_staffs_list = @reservation.reservation_menus.includes(:menu).map.with_index do |rm, position|
        {
          menu: view_context.custom_option(@menu_result[:menu_options].find { |option| option.id == rm.menu_id }),
          position: rm.position || position,
          menu_id: rm.menu_id,
          menu_required_time: rm.required_time,
          menu_interval_time: rm.menu.interval,
          staff_ids: []
        }
      end

      staff_ids = @staff_options.map(&:id)
      @reservation.reservation_staffs.each do |reservation_staff|
        menu_hash = @menu_staffs_list.find { |menu_item| menu_item[:menu_id] == reservation_staff.menu_id }
        menu_hash[:staff_ids] << { staff_id: (staff_ids.include?(reservation_staff.staff_id) ? reservation_staff.staff_id : nil) }
      end

      @customers_list ||= @reservation.reservation_customers.includes(:customer).map do |reservation_customer|
        customer = reservation_customer.customer

        reservation_customer.attributes.merge!(
          binding: true, # had reservation_customer record
          label: customer.name,
          value: customer.id,
          address: customer.address,
          details: reservation_customer.details.to_json,
          booking_price: render_to_string(partial: "reservations/show_modal/booking_price", locals: { reservation_customer: reservation_customer }),
          booking_from: render_to_string(
            partial: "reservations/show_modal/booking_from",
            locals: { reservation_customer: reservation_customer, reservation: @reservation, current_user_staff: current_user_staff }
          ),
          booking_customer_info_changed: render_to_string(
            partial: "reservations/show_modal/customer_info_changed",
            locals: { reservation_customer: reservation_customer }
          )
        )
      end

      @staff_states = @reservation.reservation_staffs.map { |rs| { staff_id: rs.staff_id, state: rs.state }}
    end

    @menu_staffs_list = @menu_staffs_list.size != 0 ? @menu_staffs_list : [
      {
        menu_id: "",
        position: 0,
        menu_required_time: "",
        menu_interval_time: "",
        staff_ids: [{
          staff_id: ""
        }]
      }
    ]

    Rails.cache.delete(reservation_params_hash_cache_key)
    cookies.clear_across_domains(:reservation_form_hash)

    if params[:customer_id]
      customer = super_user.customers.find(params[:customer_id])

      if @customers_list.map { |c| c["customer_id"].to_i }.exclude?(params[:customer_id].to_i)
        @customers_list << {
          customer_id: params[:customer_id].to_i,
          state: "accepted",
          label: customer.name,
          value: customer.id,
          address: customer.address
        }
      end
    end
  end

  def create
    authorize! :manage_shop_reservations, shop

    outcome = Reservations::Save.run(reservation: shop.reservations.new, params: reservation_params_hash)

    if outcome.valid?
      if in_personal_dashboard?
        redirect_to date_member_path(reservation_date: outcome.result.start_time.to_fs(:date))
      else
        redirect_to shop_reservations_path(shop, reservation_date: reservation_params_hash[:start_time_date_part]), notice: I18n.t("reservation.create_successfully_message")
      end
    else
      # Rollbar.warning("Create reservation failed",
      #   errors_messages: outcome.errors.full_messages.join(", "),
      #   errors_details: outcome.errors.details,
      #   params: reservation_params_hash
      # )
      redirect_to form_shop_reservations_path(shop, reservation_params_hash.to_h), alert: outcome.errors.full_messages.join(", ")
    end
  end

  def update
    authorize! :manage_shop_reservations, shop
    authorize! :edit, @reservation
    outcome = Reservations::Save.run(reservation: @reservation, params: reservation_params_hash)

    if outcome.valid?
      if params[:from_customer_id].present?
        redirect_to user_customers_path(shop.user, customer_id: params[:from_customer_id])
      elsif in_personal_dashboard?
        redirect_to date_member_path(reservation_date: outcome.result.start_time.to_fs(:date))
      else
        redirect_to shop_reservations_path(shop, reservation_date: reservation_params_hash[:start_time_date_part]), notice: I18n.t("reservation.update_successfully_message")
      end
    else
      # Rollbar.warning("Update reservation failed",
      #   errors_messages: outcome.errors.full_messages.join(", "),
      #   errors_details: outcome.errors.details,
      #   params: reservation_params_hash
      # )
      redirect_to form_shop_reservations_path(shop, reservation_params_hash.to_h), alert: outcome.errors.full_messages.join(", ")
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

  # def validate
  #   outcome = Reservable::Time.run(shop: shop, date: Time.zone.parse(params[:reservation_form][:start_time_date_part]).to_date)
  #   @time_ranges = outcome.valid? ? outcome.result : nil
  #
  #   @customer_max_load_capability = Array.wrap(reservation_params_hash[:menu_staffs_list]).map do |menu_staffs_list|
  #     # XXX: When there is the same menu, the second staffs would merge into first menu, then second menu's staff would disappear, unlikely case
  #     staff_ids = Array.wrap(menu_staffs_list[:staff_ids]).map { |hh| hh[:staff_id] }.compact
  #
  #     if staff_ids.blank?
  #       0
  #     else
  #       Reservable::CalculateCapabilityForCustomers.run!(
  #         shop: shop,
  #         menu_id: menu_staffs_list[:menu_id],
  #         staff_ids: staff_ids.uniq
  #       )
  #     end
  #   end.min
  #
  #   reservation_errors
  # end

  def add_customer
    Rails.cache.write(reservation_params_hash_cache_key, reservation_params_hash.to_json)

    render json: { redirect_to: user_customers_path(super_user, reservation_id: reservation_params_hash[:reservation_id], from_reservation: true) }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = shop.reservations.find(params[:id] || params[:reservation_form][:id])
  end

  # def start_time
  #   @start_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
  # end
  #
  # def end_time
  #   @end_time ||= Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
  # end

  def all_options
    menu_options = ShopMenu.includes(:menu).where(shop: shop).where("menus.deleted_at": nil).references(:menus).map do |shop_menu|
      ::Options::MenuOption.new(
        id: shop_menu.menu_id,
        name: shop_menu.menu.display_name,
        min_staffs_number: shop_menu.menu.min_staffs_number,
        available_seat: shop_menu.max_seat_number,
        minutes: shop_menu.menu.minutes,
        interval: shop_menu.menu.interval,
        online: shop_menu.menu.online
      )
    end
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options =
      if super_user.premium_member?
        shop.staffs.order("id").uniq.map do |staff|
          ::Option.new(id: staff.id, name: staff.name, handable_customers: nil)
        end
      else
        [
          ::Option.new(id: current_user_staff.id, name: current_user_staff.name, handable_customers: nil)
        ]
      end
  end

  def reservation_errors
    @errors_with_warnings = Reservations::Validate.run!(
      reservation: @reservation || shop.reservations.find_by(id: params[:reservation_form][:reservation_id]) || shop.reservations.new,
      params: reservation_params_hash
    )
  end

  def set_current_dashboard_mode
    cookies.set_across_domains(:dashboard_mode, shop.id, expires: 20.years.from_now)
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
    if @reservation_params_hash[:customers_list].present?
      @reservation_params_hash[:customers_list].map! { |h| h.merge!(details: JSON.parse(h["details"].presence || "{}")) }
      @reservation_params_hash[:customers_list].map! { |h| h[:booking_at].present? ? h.merge!(booking_at: Time.parse(h[:booking_at])) : h }
      convert_params(@reservation_params_hash[:customers_list])
    end

    if @reservation_params_hash[:staff_states].present?
      convert_params(@reservation_params_hash[:staff_states])
    end

    if @reservation_params_hash[:menu_staffs_list].present?
      convert_params(@reservation_params_hash[:menu_staffs_list])
    end
    @reservation_params_hash
  end

  def reservation_params_hash_cache_key
    "user_id-#{current_user.id}-reservation_params_hash"
  end
end
