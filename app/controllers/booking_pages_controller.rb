# frozen_string_literal: true

require "mixpanel_tracker"
require "flow_backtracer"

class BookingPagesController < ActionController::Base
  include MixpanelHelper
  include ProductLocale

  rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_booking_show_page
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [:booking_reservation]
  before_action :tracking_from, only: [:show]
  layout "booking"

  def show
    cookies.clear_across_domains(:oauth_social_account_id, :who)
    if !booking_page.user.subscription.active?
      render inline: t("common.no_service_warning_html")
      return
    end

    if booking_page.draft
      if !current_user || !current_user.current_staff_account(booking_page.user)
        redirect_to root_path, alert: I18n.t("common.no_permission")
        return
      end
    end

    @social_customer = nil
    @customer =
      if params[:social_user_id] || cookies[:line_social_user_id_of_customer]
        @social_customer = @booking_page.user.social_customers.find_by(social_user_id: params[:social_user_id] || cookies[:line_social_user_id_of_customer])
        @social_customer&.customer
      end

    @customer ||=
      if cookies[:booking_customer_id] || cookies[:verified_customer_id]
        @booking_page.user.customers.find_by(id: cookies[:booking_customer_id] || cookies[:verified_customer_id])
      end

    @last_selected_option_ids =
      if params[:last_booking_option_ids] || params[:last_booking_option_id]
        params[:last_booking_option_ids]&.split(",")&.map(&:to_i) || [params[:last_booking_option_id].to_i]
      elsif @customer
        @customer.reservation_customers.joins(:reservation).where("reservations.aasm_state": "checked_in").last&.booking_option_ids
      else
        []
      end

    if @customer
      Current.customer = @customer
    else
      Current.customer = params[:social_user_id] || SecureRandom.uuid
    end

    active_booking_options_number = @booking_page.booking_options.active.count
    @has_active_booking_option =  !active_booking_options_number.zero?
    @is_single_booking_option = active_booking_options_number == 1

    if @is_single_booking_option
      first_special_date = @booking_page.booking_page_special_dates.order("start_at").first

      if first_special_date && first_special_date.start_at > Time.current
        @default_selected_date = first_special_date.start_at.to_fs(:date)
      end
    end

    @booking_options_quota = @booking_page.booking_options.active.each_with_object({}) do |booking_option, h|
      if ticket = @customer&.active_customer_ticket_of_product(booking_option)
        h[booking_option.id.to_s] = {
          booking_option_id: booking_option.id,
          booking_option_name: booking_option.present_name  ,
          total_quota: ticket.total_quota,
          consumed_quota: ticket.consumed_quota,
          ticket_code: ticket.code,
          expire_date: I18n.l(ticket.expire_at, format: :date)
        }
      elsif booking_option.ticket_enabled?
        h[booking_option.id.to_s] = {
          booking_option_id: booking_option.id,
          booking_option_name: booking_option.present_name,
          total_quota: booking_option.ticket_quota,
          consumed_quota: 0,
          ticket_code: nil,
          expire_date: nil,
          expire_month: booking_option.ticket_expire_month
        }
      end
    end

    @social_account = @booking_page.user.social_accounts.first

    if @booking_page.product_requirement
      if !@customer || @booking_page.requirement_customers.exclude?(@customer)
        @product_requirement = @booking_page.product_requirement
      end
    end

    @booking_page_options = @booking_page.booking_page_options.includes(:booking_option).references(:booking_options)
  end

  def booking_reservation
    params.permit!

    # Use Redis to prevent duplicate bookings for same time slot and options
    booking_key = "booking_request:#{params[:booking_date]}:#{params[:booking_at]}:#{params[:booking_option_ids] || params[:booking_option_id]}:#{params[:social_user_id]}"
    if Rails.cache.read(booking_key).present?
      return render json: {
        status: "failed",
        errors: { message: I18n.t("booking_page.message.timeslot_already_booked") }
      }
    end

    # Set lock for 30 seconds
    Rails.cache.write(booking_key, true, expires_in: 30.seconds)

    outcome = Booking::CreateReservationForTimeslot.run(
      booking_page_id: params[:id].to_i,
      staff_ids: staff_ids,
      booking_option_ids: booking_option_ids,
      booking_start_at: Time.zone.parse("#{params[:booking_date]} #{params[:booking_at]}"),
      customer_last_name: params[:customer_last_name],
      customer_first_name: params[:customer_first_name],
      customer_phonetic_last_name: params[:customer_phonetic_last_name],
      customer_phonetic_first_name: params[:customer_phonetic_first_name],
      customer_phone_number: params[:customer_phone_number],
      customer_email: params[:customer_email],
      customer_reminder_permission: ActiveModel::Type::Boolean.new.cast(params[:reminder_permission]),
      customer_info: params[:customer_info].to_h,
      present_customer_info: params[:present_customer_info].to_h,
      social_user_id: params[:social_user_id],
      stripe_token: params[:stripe_token],
      square_token: params[:square_token],
      square_location_id: params[:square_location_id],
      sale_page_id: params[:sale_page_id],
      survey_answers: params[:survey_answers],
      function_access_id: params[:function_access_id]
    )

    if outcome.valid?
      result = outcome.result
      customer = result[:customer]

      cookies.clear_across_domains(:booking_customer_id)
      cookies.set_across_domains(:booking_customer_id, customer&.id, expires: 20.years.from_now)

      Booking::FinalizeCode.run(booking_page: booking_page, uuid: params[:uuid], customer: customer, reservation: result[:reservation])

      render json: {
        status: "successful"
      }
    else
      booking_page.touch
      Rollbar.error("#{outcome.class} service failed", {
        errors: outcome.errors.details,
        user_id: booking_page.user_id
      })
      render json: {
        status: "failed",
        errors: {
          message: I18n.t("booking_page.message.booking_unexpected_failed_message")
        }
      }
    end
  end

  def calendar
    ::FlowBacktracer.enable(:debug_booking_page)
    ::FlowBacktracer.track(:debug_booking_page) { { "business_owner_id": booking_page.user_id } }
    special_dates = booking_page.booking_page_special_dates.where(start_at: month_dates).map do |special_date|
      {
        start_at_date_part: special_date.start_at_date,
        start_at_time_part: special_date.start_at_time,
        end_at_date_part:   special_date.end_at_date,
        end_at_time_part:   special_date.end_at_time
      }.to_json
    end

    outcome = Booking::CalendarForTimeslot.run(
          shop: booking_page.shop,
          booking_page: booking_page,
          staff_ids: staff_ids,
          date_range: month_dates,
          booking_option_ids: booking_option_ids,
          special_dates: special_dates,
          interval: booking_page.interval,
          overbooking_restriction: booking_page.overbooking_restriction,
          customer: params[:customer_id] ? Customer.find_by(id: params[:customer_id]) : nil,
        )

    if outcome.valid?
      @schedules, @available_booking_dates = outcome.result
    else
      Rollbar.error("#{outcome.class} service failed", { errors: outcome.errors.details })
    end

    render template: "calendars/working_schedule"
  end

  def booking_times
    ::FlowBacktracer.enable(:debug_booking_page)

    booking_dates = if booking_page.booking_page_special_dates.exists?
      booking_page.booking_page_special_dates.where(start_at: date.all_day).map do |matched_special_date|
        {
          start_at_date_part: matched_special_date.start_at_date,
          start_at_time_part: matched_special_date.start_at_time,
          end_at_date_part:   matched_special_date.end_at_date,
          end_at_time_part:   matched_special_date.end_at_time
        }.to_json
      end
    else
      time_outcome = Reservable::Time.run(shop: booking_page.shop, booking_page: booking_page, date: params[:date])

      if time_outcome.valid?
        time_outcome.result.map do |working_time|
          work_start_at = working_time.first
          work_end_at = working_time.last

          {
            start_at_date_part: work_start_at.to_date.to_fs,
            start_at_time_part: I18n.l(work_start_at, format: :hour_minute),
            end_at_date_part:   work_end_at.to_date.to_fs,
            end_at_time_part:   I18n.l(work_end_at, format: :hour_minute)
          }.to_json
        end
      else
        []
      end
    end

    outcome = Booking::AvailableBookingTimesForTimeslot.run(
      shop: booking_page.shop,
      booking_page: booking_page,
      booking_option_ids: booking_option_ids,
      staff_ids: staff_ids,
      special_dates: booking_dates,
      interval: booking_page.interval,
      overbooking_restriction: booking_page.overbooking_restriction,
      customer: params[:customer_id] ? Customer.find_by(id: params[:customer_id]) : nil
    )

    available_booking_times = outcome.result.each_with_object({}) { |(time, option_ids), h| h[I18n.l(time, format: :hour_minute)] = option_ids  }

    if outcome.valid?
      render json: { booking_times: available_booking_times, debug: ::FlowBacktracer.backtrace(:debug_booking_page) }
    else
      Rollbar.error("#{outcome.class} service failed", { errors: outcome.errors.details })
      render json: { booking_times: {} }
    end
  end

  private

  def date
    @date ||= params[:date].present? ? Time.zone.parse(params[:date]).to_date : Time.zone.now.to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end

  def booking_page
    @booking_page ||= BookingPage.active.find_by(slug: params[:id]) || BookingPage.active.find(params[:id])
  end

  def redirect_to_booking_show_page(exception)
    Rollbar.error(exception)
    render json: { status: "invalid_authenticity_token" }
  end

  def product_social_user
    booking_page.user.social_user
  end

  def booking_option_ids
    @booking_option_ids ||= params[:booking_option_ids].presence || [params[:booking_option_id]]
  end

  def staff_ids
    @staff_ids ||= begin
      menu_ids = BookingOptionMenu.where(booking_option_id: booking_option_ids).pluck(:menu_id)
      StaffMenu.where(menu_id: menu_ids).group(:staff_id).having("COUNT(menu_id) = ?", menu_ids.size).pluck(:staff_id)
    end
  end
end
