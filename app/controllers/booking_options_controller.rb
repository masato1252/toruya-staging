# frozen_string_literal: true

require "mixpanel_tracker"
require "flow_backtracer"

class BookingOptionsController < ActionController::Base
  include MixpanelHelper
  rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_booking_show_page
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [:booking_reservation]
  before_action :tracking_from, only: [:show]

  layout "booking"

  def show
    @social_customer = nil
    @customer =
      if params[:social_user_id] || cookies[:line_social_user_id_of_customer]
        @social_customer = @booking_option.user.social_customers.find_by(social_user_id: params[:social_user_id] || cookies[:line_social_user_id_of_customer])
        @social_customer&.customer
      end

    @customer ||=
      if cookies[:booking_customer_id]
        @booking_page.user.customers.find_by(id: cookies[:booking_customer_id])
      end

    if @customer
      Current.customer = @customer
    else
      Current.customer = params[:social_user_id] || SecureRandom.uuid
    end

    @is_single_booking_option = true
    h = {}
    @booking_options_quota =
      if ticket = @customer&.active_customer_ticket_of_product(booking_option)
        h[booking_option.id.to_s] = { total_quota: ticket.total_quota, consumed_quota: ticket.consumed_quota, ticket_code: ticket.code, expire_date: I18n.l(ticket.expire_at, format: :date) }
      elsif booking_option.ticket_enabled?
        h[booking_option.id.to_s] = { total_quota: booking_option.ticket_quota, consumed_quota: 0, ticket_code: nil, expire_date: nil, expire_month: booking_option.ticket_expire_month }
      end

    @social_account = booking_option.user.social_accounts.first
  end

  def booking_reservation
    params.permit!
    outcome = Booking::CreateReservation.run(
      booking_page_id: params[:id].to_i,
      booking_option_id: params[:booking_option_id],
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
      sale_page_id: params[:sale_page_id]
    )

    if outcome.valid?
      result = outcome.result
      customer = result[:customer]

      cookies.permanent[:booking_customer_id] = customer&.id

      Booking::FinalizeCode.run(booking_page: booking_page, uuid: params[:uuid], customer: customer, reservation: result[:reservation])

      render json: {
        status: "successful"
      }
    else
      render json: {
        status: "failed",
        errors: {
          message: I18n.t("booking_page.message.booking_unexpected_failed_message")
        }
      }
    end
  end

  def find_customer
    customer = Booking::FindCustomer.run!(
      booking_page: booking_page,
      first_name: params[:customer_first_name],
      last_name: params[:customer_last_name],
      phone_number: params[:customer_phone_number]
    )

    if customer
      cookies.permanent[:booking_customer_id] = customer.id

      render json: {
        customer_info: view_context.customer_info_as_json(customer),
        last_selected_option_id: customer.reservation_customers.joins(:reservation).where("reservations.aasm_state": "checked_in").last&.booking_option_id,
        booking_code: {
          passed: true
        }
      }
    else
      render json: {
        customer_info: {},
        booking_code: {
          passed: true
        },
        errors: {
          message: I18n.t("booking_page.message.unfound_customer_html")
        }
      }
    end
  end

  def ask_confirmation_code
    booking_code = Booking::CreateCode.run!(
      booking_page: booking_page,
      phone_number: params[:customer_phone_number]
    )

    render json: {
      booking_code: {
        uuid: booking_code.uuid
      }
    }
  end

  def confirm_code
    code_passed = !!IdentificationCodes::Verify.run!(uuid: params[:uuid], code: params[:code])

    if code_passed
      render json: {
        booking_code: {
          passed: code_passed
        }
      }
    else
      render json: {
        booking_code: {
          passed: code_passed
        },
        errors: {
          message: I18n.t("booking_page.message.booking_code_failed_message")
        }
      }
    end
  end

  def calendar
    special_dates = booking_page.booking_page_special_dates.where(start_at: month_dates).map do |special_date|
      {
        start_at_date_part: special_date.start_at_date,
        start_at_time_part: special_date.start_at_time,
        end_at_date_part:   special_date.end_at_date,
        end_at_time_part:   special_date.end_at_time
      }.to_json
    end

    outcome = Booking::Calendar.run(
      shop: booking_page.shop,
      booking_page: booking_page,
      date_range: month_dates,
      booking_option_ids: params[:booking_option_id] ? [params[:booking_option_id]] : booking_page.booking_option_ids,
      special_dates: special_dates,
      special_date_type: booking_page.booking_page_special_dates.exists?,
      interval: booking_page.interval,
      overbooking_restriction: booking_page.overbooking_restriction,
      customer: params[:customer_id] ? Customer.find_by(id: params[:customer_id]) : nil,
    )

    if outcome.valid?
      @schedules, @available_booking_dates = outcome.result
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

    outcome = Booking::AvailableBookingTimes.run(
      shop: booking_page.shop,
      booking_page: booking_page,
      special_dates: booking_dates,
      booking_option_ids: params[:booking_option_id] ? [params[:booking_option_id]] : booking_page.booking_option_ids,
      interval: booking_page.interval,
      overbooking_restriction: booking_page.overbooking_restriction,
      customer: params[:customer_id] ? Customer.find_by(id: params[:customer_id]) : nil
    )

    available_booking_times = outcome.result.each_with_object({}) { |(time, option_ids), h| h[I18n.l(time, format: :hour_minute)] = option_ids  }

    if outcome.valid?
      render json: { booking_times: available_booking_times, debug: ::FlowBacktracer.backtrace(:debug_booking_page) }
    else
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

  def booking_option
    @booking_option ||= BookingOption.active.find_by(slug: params[:slug])
  end

  def redirect_to_booking_show_page(exception)
    Rollbar.error(exception)
    render json: { status: "invalid_authenticity_token" }
  end
end
