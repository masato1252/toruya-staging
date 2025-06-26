# frozen_string_literal: true

module Booking
  class AvailableBookingTimesForTimeslot < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    # booking_option_ids
    # ["1"]
    object :booking_page
    array :booking_option_ids # ["1"] # the booking option ids that want to book, not candidate booking options
    array :staff_ids # [1] # candidate staffs
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates
    integer :interval
    boolean :overbooking_restriction, default: true
    integer :limit, default: nil
    object :customer, default: nil
    boolean :force_update_cache, default: false

    def execute
      return {} if special_dates.blank?

      raw_special_date = special_dates.first
      json_parsed_date = JSON.parse(raw_special_date)
      special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])

      if special_date.today?
        # Performance optimization: Preload data for today's requests to avoid N+1 queries
        preload_data_for_special_dates
        process_available_booking_times(special_date)
      else
        Rails.cache.fetch(cache_key(special_date), expires_in: 12.hours, force: force_update_cache) do
          # Performance optimization: Only preload data during cache miss
          preload_data_for_special_dates
          process_available_booking_times(special_date)
        end
      end
    end

    private

    def process_available_booking_times(special_date)
      available_booking_time_mapping = {}

      catch :enough_booking_time do
        special_dates.each do |raw_special_date|
          catch :next_working_date do
            json_parsed_date = JSON.parse(raw_special_date)
            special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])

            special_date_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{json_parsed_date[START_AT_TIME_PART]}")
            special_date_end_at = Time.zone.parse("#{json_parsed_date[END_AT_DATE_PART]}-#{json_parsed_date[END_AT_TIME_PART]}")

            if special_date < booking_page.available_booking_start_date || special_date > booking_page.available_booking_end_date
              next
            end

            available_booking_times = []
            booking_start_at = special_date_start_at
            total_required_time = booking_options_total_minutes # Use cached result

            if booking_page.specific_booking_start_times.present?
              booking_page.specific_booking_start_times.each do |start_time_time_part|
                booking_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{start_time_time_part}")
                booking_end_at = booking_start_at.advance(minutes: total_required_time)

                if booking_end_at > special_date_end_at
                    break
                  end

                  loop_for_reserable_timeslot(
                    shop: shop,
                    staff_ids: staff_ids,
                    booking_page: booking_page,
                    booking_options: booking_options,
                    date: booking_start_at.to_date,
                    booking_start_at: booking_start_at,
                    overbooking_restriction: overbooking_restriction
                  ) do
                    available_booking_times << booking_start_at

                    available_booking_time_mapping[booking_start_at] ||= []
                    available_booking_time_mapping[booking_start_at] << booking_option_ids

                    throw :enough_booking_time if limit && available_booking_times.length >= limit
                end
              end
            else
              loop do
                booking_end_at = booking_start_at.advance(minutes: total_required_time)

                if booking_end_at > special_date_end_at
                  break
                end

                loop_for_reserable_timeslot(
                  shop: shop,
                  staff_ids: staff_ids,
                  booking_page: booking_page,
                  booking_options: booking_options,
                  date: booking_start_at.to_date,
                  booking_start_at: booking_start_at,
                  overbooking_restriction: overbooking_restriction
                ) do
                  available_booking_times << booking_start_at

                  available_booking_time_mapping[booking_start_at] ||= []
                  available_booking_time_mapping[booking_start_at] << booking_option_ids

                  throw :enough_booking_time if limit && available_booking_times.length >= limit
                end

                booking_start_at = booking_start_at.advance(minutes: interval)
              end
            end
          end
        end
      end

      available_booking_time_mapping
    end

    # Performance optimization: Preload data for special dates to avoid N+1 queries during cache miss
    def preload_data_for_special_dates
      return if @cache_data_loaded

      # Parse all special_dates to get the date range
      all_dates = special_dates.map do |raw_special_date|
        json_parsed_date = JSON.parse(raw_special_date)
        Date.parse(json_parsed_date[START_AT_DATE_PART])
      end.uniq.select { |date| date >= booking_page.available_booking_start_date && date <= booking_page.available_booking_end_date }

      return if all_dates.empty?

      # Batch load all required data
      @reservation_data = {}
      @custom_schedule_data = {}

      # Batch query all reservation data for dates
      reservations_by_date = shop.reservations
        .where(start_time: all_dates.first.beginning_of_day..all_dates.last.end_of_day)
        .group_by { |r| r.start_time.to_date }

      @reservation_data = all_dates.each_with_object({}) do |date, hash|
        hash[date] = reservations_by_date[date]&.max_by(&:updated_at)
      end

      # Batch query CustomSchedule data
      custom_schedules_by_date = CustomSchedule
        .closed
        .where(user_id: staff_user_ids)
        .where(start_time: all_dates.first.beginning_of_day..all_dates.last.end_of_day)
        .group_by { |cs| cs.start_time.to_date }

      @custom_schedule_data = all_dates.each_with_object({}) do |date, hash|
        hash[date] = custom_schedules_by_date[date]&.max_by(&:updated_at)
      end

      # Cache other frequently accessed data
      @business_schedule_last = BusinessSchedule.where(shop: shop).order("updated_at").last
      @booking_page_special_dates_count = BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).count
      @booking_page_special_dates_last = BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).order("updated_at").last

      @cache_data_loaded = true
    end

    # Simplified cache_key - avoid expensive queries when cache exists
    def cache_key(date)
      [
        'available_booking_times',
        booking_page,
        date,
        shop,
        booking_option_ids,
        staff_ids,
        cached_reservation_data(date), # Use cached or simple lookup
        cached_custom_schedule_data(date), # Use cached or simple lookup
        cached_business_schedule_last,
        cached_booking_page_special_dates_count,
        cached_booking_page_special_dates_last,
        booking_options_updated_at,
        booking_option_menus_updated_at,
      ]
    end

    # Use preloaded data if available, otherwise fallback to individual queries
    def cached_reservation_data(date)
      @reservation_data&.dig(date) ||
        shop.reservations.where(start_time: date.beginning_of_day..date.end_of_day).order(:updated_at).last
    end

    def cached_custom_schedule_data(date)
      @custom_schedule_data&.dig(date) ||
        CustomSchedule.closed.where(user_id: staff_user_ids, start_time: date.beginning_of_day..date.end_of_day).order(:updated_at).last
    end

    def cached_business_schedule_last
      @business_schedule_last ||= BusinessSchedule.where(shop: shop).order("updated_at").last
    end

    def cached_booking_page_special_dates_count
      @booking_page_special_dates_count ||= BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).count
    end

    def cached_booking_page_special_dates_last
      @booking_page_special_dates_last ||= BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).order("updated_at").last
    end

    def booking_options
      @booking_options ||= compose(
        BookingOptions::Prioritize,
        booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
      )
    end

    # Performance optimization: Avoid repeated calculations
    def booking_options_updated_at
      @booking_options_updated_at ||= begin
        # Use a single SQL query to get all updated_at values
        shop.user.booking_options
          .where(id: booking_option_ids)
          .pluck(:updated_at)
      end
    end

    # Performance optimization: Avoid repeated calculations and N+1 queries
    def booking_option_menus_updated_at
      @booking_option_menus_updated_at ||= begin
        # Use join query to avoid N+1 problem
        Menu.joins(:booking_option_menus)
          .where(booking_option_menus: { booking_option_id: booking_option_ids })
          .distinct
          .pluck(:updated_at)
      end
    end

    def staff_user_ids
      @staff_user_ids ||= shop.staff_users.pluck(:id)
    end

    # Performance optimization: Cache repeated calculation results
    def booking_options_total_minutes
      @booking_options_total_minutes ||= booking_options.sum(&:minutes)
    end
  end
end