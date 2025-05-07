# frozen_string_literal: true

# params[:from]
# customer_dashboard: customer dashboard -> reservation form(let reservation form know, it is from customer dashboard, for something like update)
# adding_customer: customer dashboard -> reservation form(let reservation form know, it is from customer dashboard, for adding customer)
# reservation: reservation form -> customer dashboard(let Customer dashboard know, it is from reservation)
require "site_routing"

class Lines::UserBot::ReservationsController < Lines::UserBotDashboardController
  include SchedulesHelper
  SCHEDULE_CHECKING = "reservations_schedule_checking"
  before_action :set_reservation, only: [:update, :destroy]

  def show
    @reservation = Reservation.find(params[:id])

    @sentences = view_context.reservation_staff_sentences(@reservation)
    @shop_user = @reservation.shop.user
    @user_ability = ability(@shop_user, @reservation.shop)
    if params[:customer_id]
      @customer = Customer.find_by(id: params[:customer_id])
      @reservation_customer = ReservationCustomer.find_by(reservation_id: @reservation.id, customer_id: params[:customer_id])
      @paid_payment = @reservation_customer&.paid_payment
      @survey_response = @reservation_customer&.survey_response
    else
      @reservation_customers = @reservation.reservation_customers
      @survey_responses = @reservation_customers.map(&:survey_response).compact
    end

    template = params[:from] == "customer_dashboard" ? "reservations/customer_reservation_show" : "reservations/show"

    render template: template, layout: false
  end

  def form
    all_options

    if Rails.cache.read(reservation_params_hash_cache_key) && params[:from] == "adding_customer"
      reservarion_params = JSON.parse(Rails.cache.read(reservation_params_hash_cache_key)).with_indifferent_access
      menu_staffs_list = reservarion_params.delete(:menu_staffs_list)
      customers_list = reservarion_params.delete(:customers_list)
      reservation_id = reservarion_params.delete(:reservation_id)
      staff_states = reservarion_params.delete(:staff_states)
      business_owner_id = reservarion_params.delete(:business_owner_id)

      @reservation = shop.reservations.find_or_initialize_by(id: reservation_id)
      @reservation.attributes = reservarion_params
      @menu_staffs_list = menu_staffs_list
      @staff_states = staff_states.presence || []
      @customers_list = Array.wrap(customers_list).map {|h| h.merge!(details: h[:details]&.to_json ) }
    else
      @reservation = shop.reservations.find_by(id: params[:id] || params[:reservation_id])
      @reservation ||= shop.reservations.new(
        start_time_date_part: params[:start_time_date_part] || Time.zone.now.to_fs(:date),
        start_time_time_part: Time.zone.now.to_fs(:time),
        end_time_date_part: params[:start_time_date_part] || Time.zone.now.to_fs(:date),
        end_time_time_part: Time.zone.now.advance(hours: 2).to_fs(:time),
      )
      @menu_staffs_list = @reservation.reservation_menus.includes(:menu).map.with_index do |rm, position|
        menu_option = @menu_result[:menu_options].find { |option| option.id == rm.menu_id }

        {
          menu: menu_option ? view_context.custom_option(menu_option) : nil,
          position: rm.position || position,
          menu_id: rm.menu_id,
          menu_required_time: rm.required_time,
          menu_interval_time: rm.menu.interval,
          staff_ids: [],
          menu_online: rm.menu.online
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
          label: customer&.name,
          value: customer&.id,
          address: customer&.address,
          details: reservation_customer.details.to_json,
          reminderPermission: customer&.reminder_permission,
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
        }],
        menu_online: ""
      }
    ]

    Rails.cache.delete(reservation_params_hash_cache_key)

    if params[:customer_id]
      customer = Current.business_owner.customers.find(params[:customer_id])

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

    outcome = ::Reservations::Save.run(reservation: shop.reservations.new, params: reservation_params_hash)

    if outcome.valid?
      notify_user_customer_reservation_confirmation_message
      render json: {
        status: "successful",
        redirect_to: SiteRouting.new(view_context).schedule_date_path(reservation_date: outcome.result.start_time.to_fs(:date))
      }
    else
      # Rollbar.warning("Create reservation failed",
      #   errors_messages: outcome.errors.full_messages.join(", "),
      #   errors_details: outcome.errors.details,
      #   params: reservation_params_hash
      # )
      redirect_to form_lines_user_bot_shop_reservations_path(reservation_params_hash.to_h), alert: outcome.errors.full_messages.join(", ")
    end
  end

  def update
    authorize! :manage_shop_reservations, shop
    authorize! :edit, @reservation
    outcome = ::Reservations::Save.run(reservation: @reservation, params: reservation_params_hash)

    if outcome.valid?
      notify_user_customer_reservation_confirmation_message

      if params[:from] == "customer_dashboard" && params[:customer_id].present?
        render json: {
          status: "successful",
          redirect_to: SiteRouting.new(view_context).customers_path(@reservation.shop.user_id, customer_id: params[:customer_id], reservation_id: @reservation.id)
        }
      else
        render json: {
          status: "successful",
          redirect_to: SiteRouting.new(view_context).schedule_date_path(reservation_date: outcome.result.start_time.to_fs(:date))
        }
      end
    else
      # Rollbar.warning("Update reservation failed",
      #   errors_messages: outcome.errors.full_messages.join(", "),
      #   errors_details: outcome.errors.details,
      #   params: reservation_params_hash
      # )
      redirect_to form_lines_user_bot_shop_reservations_path(reservation_params_hash.to_h), alert: outcome.errors.full_messages.join(", ")
    end
  end

  def destroy
    authorize! :edit, @reservation

    Reservations::Delete.run!(reservation: @reservation)

    if params[:from] == "customer_dashboard" && params[:customer_id].present?
      redirect_to SiteRouting.new(view_context).customers_path(shop.user_id, shop_id: params[:shop_id], customer_id: params[:customer_id])
    else
      redirect_to SiteRouting.new(view_context).member_path, notice: I18n.t("reservation.delete_successfully_message")
    end
  end

  def validate
    @customer_max_load_capability = Array.wrap(reservation_params_hash[:menu_staffs_list]).map do |menu_staffs_list|
      # XXX: When there is the same menu, the second staffs would merge into first menu, then second menu's staff would disappear, unlikely case
      staff_ids = Array.wrap(menu_staffs_list[:staff_ids]).map { |hh| hh[:staff_id] }.compact

      if staff_ids.blank?
        0
      else
        Reservable::CalculateCapabilityForCustomers.run!(
          shop: shop,
          menu_id: menu_staffs_list[:menu_id],
          staff_ids: staff_ids.uniq
        )
      end
    end.min

    reservation_errors

    render template: "reservations/validate"
  end

  def add_customer
    Rails.cache.write(reservation_params_hash_cache_key, reservation_params_hash.to_json)

    render json: {
      redirect_to: SiteRouting.new(view_context).customers_path(
        Current.business_owner.id,
        reservation_id: reservation_params_hash[:reservation_id],
        shop_id: params[:shop_id],
        from: "reservation"
      )
    }
  end

  def schedule
    working_shop_ids = Current.business_owner.shop_ids

    @date = Time.zone.parse(params[:reservation_date]).to_date

    schedules = Schedules::Events.run!(
      working_shop_ids: working_shop_ids,
      user_ids: Current.business_owner.all_staff_related_users.pluck(:id),
      date: @date,
    )

    @schedules = schedules_events(schedules)
    @related_user_ids = Current.business_owner.related_users.map(&:id)

    render layout: false
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = shop.reservations.find(params[:id])
  end

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
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options =
      Current.business_owner.staffs.map do |staff|
        ::Option.new(id: staff.id, name: staff.name, handable_customers: nil)
      end
  end

  def reservation_errors
    @errors_with_warnings = ::Reservations::Validate.run!(
      reservation: @reservation || shop.reservations.find_by(id: params[:reservation_id]) || shop.reservations.new,
      params: reservation_params_hash
    )
  end

  def set_current_dashboard_mode
    cookies[:dashboard_mode] = {
      value: shop.id,
      domain: :all
    }
  end

  def reservation_params_hash
    return @reservation_params_hash if defined?(@reservation_params_hash)

    @reservation_params_hash = params.permit!.to_h

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

    @reservation_params_hash.delete(:controller)
    @reservation_params_hash.delete(:action)
    @reservation_params_hash.delete(:format)
    @reservation_params_hash.delete(:reservation)

    @reservation_params_hash
  end

  def reservation_params_hash_cache_key
    "user-bot-user_id-#{Current.business_owner.id}-reservation_params_hash"
  end
end
