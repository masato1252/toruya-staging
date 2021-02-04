# frozen_string_literal: true

require "mixpanel_tracker"

class BookingPagesController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_booking_show_page
  protect_from_forgery with: :exception, prepend: true

  layout "booking"

  def show
    if booking_page.draft
      if !current_user || !current_user.current_staff_account(booking_page.user)
        redirect_to root_path, alert: I18n.t("common.no_permission")
        return
      end
    end

    @customer =
      if params[:social_user_id]
        SocialCustomer.find_by(social_user_id: params[:social_user_id])&.customer
      end

    @customer ||=
      if cookies[:booking_customer_id]
        @booking_page.user.customers.find_by(id: cookies[:booking_customer_id])
      end

    if @customer
      @last_selected_option_id = @customer.reservation_customers.joins(:reservation).where("reservations.aasm_state": "checked_in").last&.booking_option_id
    end

    if @customer
      if params[:social_user_id]
        MixpanelTracker.track @customer.id, "view_booking_page", { from: "customer_bot" }
      else
        MixpanelTracker.track @customer.id, "view_booking_page", { from: "directly" }
      end
    else
      MixpanelTracker.track params[:social_user_id] || SecureRandom.uuid, "view_booking_page", { from: params[:from], from_id: params[:from_id] }
    end

    active_booking_options_number = @booking_page.booking_options.active.count
    @has_active_booking_option =  !active_booking_options_number.zero?
    @is_single_booking_option = active_booking_options_number == 1

    if @is_single_booking_option
      is_single_special_date = @booking_page.booking_page_special_dates.count == 1

      if is_single_special_date
        booking_dates = @booking_page.booking_page_special_dates.map do |matched_special_date|
          {
            start_at_date_part: matched_special_date.start_at_date,
            start_at_time_part: matched_special_date.start_at_time,
            end_at_date_part:   matched_special_date.end_at_date,
            end_at_time_part:   matched_special_date.end_at_time
          }.to_json
        end

        outcome = Booking::AvailableBookingTimes.run(
          shop: @booking_page.shop,
          booking_page: @booking_page,
          special_dates: booking_dates,
          booking_option_ids: @booking_page.booking_option_ids,
          interval: @booking_page.interval,
          overbooking_restriction: @booking_page.overbooking_restriction,
          limit: 2
        )

        if outcome.valid?
          available_booking_times = outcome.result.keys

          if available_booking_times.length == 1
            booking_time = available_booking_times.first

            @single_booking_time = { booking_date: booking_time.to_s(:date), booking_at: booking_time.to_s(:time) }
          end
        end
      end
    end

    @social_account = @booking_page.user.social_accounts.first
  end

  def booking_reservation
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
      customer_info: JSON.parse(params[:customer_info]),
      present_customer_info: JSON.parse(params[:present_customer_info]),
      social_user_id: params[:social_user_id]
    )

    if outcome.valid?
      result = outcome.result
      customer = result[:customer]

      cookies.permanent[:booking_customer_id] = customer&.id
      cookies.permanent[:booking_customer_phone_number] = params[:customer_phone_number]

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

    booking_code = Booking::CreateCode.run!(
      booking_page: booking_page,
      phone_number: params[:customer_phone_number]
    )

    if customer
      cookies.permanent[:booking_customer_id] = customer.id
      cookies.permanent[:booking_customer_phone_number] = params[:customer_phone_number]

      render json: {
        customer_info: view_context.customer_info_as_json(customer),
        last_selected_option_id: customer.reservation_customers.joins(:reservation).where("reservations.aasm_state": "checked_in").last&.booking_option_id,
        booking_code: {
          uuid: booking_code.uuid
        }
      }
    else
      render json: {
        customer_info: {},
        booking_code: {
          uuid: booking_code.uuid
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
      overbooking_restriction: booking_page.overbooking_restriction
    )

    if outcome.valid?
      @schedules, @available_booking_dates = outcome.result
    end

    render template: "calendars/working_schedule"
  end

  def booking_times
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
      time_outcome = Reservable::Time.run(shop: booking_page.shop, date: params[:date])

      if time_outcome.valid?
        shop_start_at = time_outcome.result.first
        shop_end_at = time_outcome.result.last

        [
          {
            start_at_date_part: shop_start_at.to_s,
            start_at_time_part: I18n.l(shop_start_at, format: :hour_minute),
            end_at_date_part:   shop_end_at.to_s,
            end_at_time_part:   I18n.l(shop_end_at, format: :hour_minute)
          }.to_json
        ]
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
      overbooking_restriction: booking_page.overbooking_restriction
    )

    available_booking_times = outcome.result.each_with_object({}) { |(time, option_ids), h| h[I18n.l(time, format: :hour_minute)] = option_ids  }

    if outcome.valid?
      render json: { booking_times: available_booking_times }
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

  def booking_page
    @booking_page ||= BookingPage.find_by(slug: params[:id]) || BookingPage.find(params[:id])
  end

  def redirect_to_booking_show_page(exception)
    Rollbar.error(exception)
    render json: { status: "invalid_authenticity_token" }
  end
end
