class BookingPagesController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true

  layout "booking"

  def show
    @booking_page = BookingPage.find(params[:id])

    if @booking_page.draft
      if !current_user || !current_user.current_staff_account(@booking_page.user)
        redirect_to root_path, alert: I18n.t("common.no_permission")
        return
      end
    end

    if cookies[:booking_customer_id]
      @customer = @booking_page.user.customers.find_by(id: cookies[:booking_customer_id])&.with_google_contact
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
          special_dates: booking_dates,
          booking_option_ids: @booking_page.booking_option_ids,
          interval: @booking_page.interval,
          overlap_restriction: @booking_page.overlap_restriction,
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
  end

  def booking_reservation
    outcome = Booking::CreateReservation.run(
      booking_page_id: params[:id],
      booking_option_id: params[:booking_option_id],
      booking_start_at: Time.zone.parse("#{params[:booking_date]} #{params[:booking_at]}"),
      customer_last_name: params[:customer_last_name],
      customer_first_name: params[:customer_first_name],
      customer_phonetic_last_name: params[:customer_phonetic_last_name],
      customer_phonetic_first_name: params[:customer_phonetic_first_name],
      customer_phone_number: params[:customer_phone_number],
      customer_email: params[:customer_email],
      customer_info: JSON.parse(params[:customer_info]),
      present_customer_info: JSON.parse(params[:present_customer_info])
    )
    result = outcome.result

    if ActiveModel::Type::Boolean.new.cast(params[:remember_me])
      cookies[:booking_customer_id] = result[:customer]&.id
      cookies[:booking_customer_phone_number] = params[:customer_phone_number]
    else
      cookies.delete :booking_customer_id
      cookies.delete :booking_customer_phone_number
    end

    if result[:reservation]
      render json: {
        status: "successful"
      }
    elsif params[:customer_info].present?
      render json: {
        status: "failed",
        errors: {
          message: I18n.t("booking_page.message.booking_failed_messsage_html")
        }
      }
    else
      render json: {
        status: "failed",
        customer_info: customer&.persisted? ? view_context.customer_info_as_json(customer) : {},
        errors: {
          message: I18n.t("booking_page.message.booking_failed_messsage_html")
        }
      }
    end
  end

  def find_customer
    customer = Booking::FindCustomer.run!(
      booking_page: BookingPage.find(params[:id]),
      first_name: params[:customer_first_name],
      last_name: params[:customer_last_name],
      phone_number: params[:customer_phone_number]
    )

    if customer
      if ActiveModel::Type::Boolean.new.cast(params[:remember_me])
        cookies[:booking_customer_id] = customer.id
        cookies[:booking_customer_phone_number] = params[:customer_phone_number]
      else
        cookies.delete :booking_customer_id
        cookies.delete :booking_customer_phone_number
      end

      render json: {
        customer_info: view_context.customer_info_as_json(customer)
      }
    else
      render json: {
        customer_info: {},
        errors: {
          message: I18n.t("booking_page.message.unfound_customer_html")
        }
      }
    end
  end

  def calendar
    booking_page = BookingPage.find(params[:id])

    special_dates = booking_page.booking_page_special_dates.map do |special_date|
      {
        start_at_date_part: special_date.start_at_date,
        start_at_time_part: special_date.start_at_time,
        end_at_date_part:   special_date.end_at_date,
        end_at_time_part:   special_date.end_at_time
      }.to_json
    end

    outcome = Booking::Calendar.run(
      shop: booking_page.shop,
      date_range: month_dates,
      booking_option_ids: params[:booking_option_id] ? [params[:booking_option_id]] : booking_page.booking_option_ids,
      special_dates: special_dates,
      interval: booking_page.interval,
      overlap_restriction: booking_page.overlap_restriction
    )

    if outcome.valid?
      @schedules, @available_booking_dates = outcome.result
    end

    render template: "calendars/working_schedule"
  end

  def booking_times
    booking_page = BookingPage.find(params[:id])

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
      special_dates: booking_dates,
      booking_option_ids: params[:booking_option_id] ? [params[:booking_option_id]] : booking_page.booking_option_ids,
      interval: booking_page.interval,
      overlap_restriction: booking_page.overlap_restriction
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
    @date ||= Time.zone.parse(params[:date]).to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end
end
