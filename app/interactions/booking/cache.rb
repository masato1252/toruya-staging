# frozen_string_literal: true

module Booking
  class Cache < ActiveInteraction::Base
    object :booking_page
    object :date

    def execute
      Rails.logger.debug "🔄 Caching booking data for #{booking_page.name} on #{date}"
      start_time = Time.current

      # Early return if booking page has no booking options
      booking_option_ids = booking_page.booking_option_ids
      if booking_option_ids.empty?
        Rails.logger.debug "⚠️  No booking options for booking_page_id: #{booking_page.id}"
        return
      end

      # Validate date is within booking page range
      unless date.between?(booking_page.available_booking_start_date, booking_page.available_booking_end_date)
        Rails.logger.debug "⚠️  Date #{date} outside booking range for booking_page_id: #{booking_page.id}"
        return
      end

      # Prepare shared data once to avoid repeated calculations
      date_range = date.beginning_of_day..date.tomorrow.end_of_day
      staff_ids = [booking_page.user.current_staff.id]

      # Cache special dates query result
      special_dates = get_special_dates_for_range(date_range)

      # Cache booking dates result (shared across all booking options)
      booking_dates = get_booking_dates_for_date(date)

      Rails.logger.debug "📊 Processing #{booking_option_ids.size} booking options for date #{date}"

      successful_count = 0
      error_count = 0

      # Process each booking option with error handling
      booking_option_ids.each_with_index do |booking_option_id, index|
        option_start_time = Time.current

        begin
          # Process CalendarForTimeslot
          calendar_outcome = process_calendar_for_timeslot(
            booking_option_id: booking_option_id,
            date_range: date_range,
            staff_ids: staff_ids,
            special_dates: special_dates
          )

          # Process AvailableBookingTimesForTimeslot
          times_outcome = process_available_booking_times(
            booking_option_id: booking_option_id,
            staff_ids: staff_ids,
            booking_dates: booking_dates
          )

          successful_count += 1
          option_elapsed = Time.current - option_start_time

          # Log slow booking options for investigation
          if option_elapsed > 10.seconds
            Rails.logger.warn "⚠️  Slow booking option #{booking_option_id}: #{option_elapsed.round(2)}s"
          end

        rescue => e
          error_count += 1
          Rails.logger.error "❌ Error processing booking_option_id #{booking_option_id}: #{e.message}"
          Rails.logger.error e.backtrace.first(2).join("\n")

          # Continue processing other booking options
          next
        end
      end

      total_elapsed = Time.current - start_time
      Rails.logger.debug "✅ Cache completed for #{booking_page.name} on #{date}: " \
                         "#{successful_count}/#{booking_option_ids.size} options processed in #{total_elapsed.round(2)}s " \
                         "(#{error_count} errors)"

      if error_count > 0
        Rails.logger.warn "⚠️  #{error_count} errors occurred while caching booking_page_id: #{booking_page.id} on #{date}"
      end

    rescue => e
      Rails.logger.error "💥 Fatal error in Booking::Cache for booking_page_id: #{booking_page.id} on #{date}"
      Rails.logger.error "Error: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      raise
    end

    private

    # Cache special dates query to avoid repeated execution
    def get_special_dates_for_range(date_range)
      @special_dates ||= booking_page.booking_page_special_dates.where(start_at: date_range).map do |special_date|
        {
          start_at_date_part: special_date.start_at_date,
          start_at_time_part: special_date.start_at_time,
          end_at_date_part:   special_date.end_at_date,
          end_at_time_part:   special_date.end_at_time
        }.to_json
      end
    end

    # Cache booking dates calculation to avoid repeated execution
    def get_booking_dates_for_date(date)
      @booking_dates ||= begin
        time_outcome = Reservable::Time.run(shop: booking_page.shop, booking_page: booking_page, date: date)
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
    end

    # Process CalendarForTimeslot with error handling
    def process_calendar_for_timeslot(booking_option_id:, date_range:, staff_ids:, special_dates:)
      Booking::CalendarForTimeslot.run(
        shop: booking_page.shop,
        booking_page: booking_page,
        date_range: date_range,
        booking_option_ids: [booking_option_id],
        staff_ids: staff_ids,
        special_dates: special_dates,
        special_date_type: booking_page.booking_page_special_dates.exists?,
        interval: booking_page.interval,
        overbooking_restriction: booking_page.overbooking_restriction,
        force_update_cache: true
      )
    end

    # Process AvailableBookingTimesForTimeslot with error handling
    def process_available_booking_times(booking_option_id:, staff_ids:, booking_dates:)
      Booking::AvailableBookingTimesForTimeslot.run(
          shop: booking_page.shop,
          booking_page: booking_page,
          special_dates: booking_dates,
          booking_option_ids: [booking_option_id],
          staff_ids: staff_ids,
          interval: booking_page.interval,
          overbooking_restriction: booking_page.overbooking_restriction,
          force_update_cache: true
        )
    end
  end
end
