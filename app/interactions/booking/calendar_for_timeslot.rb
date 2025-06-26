# frozen_string_literal: true

module Booking
  class CalendarForTimeslot < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    object :booking_page
    object :date_range, class: Range
    # booking_option_ids
    # ["1"]
    array :booking_option_ids
    array :staff_ids
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates, default: nil
    boolean :special_date_type, default: false
    integer :interval, default: 30
    boolean :overbooking_restriction, default: true
    object :customer, default: nil
    boolean :force_update_cache, default: false

    def execute
      rules = compose(::Shops::WorkingCalendarRules, shop: shop, booking_page: booking_page, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      if special_date_type || special_dates.present?
        # available_working_dates = special_dates.map do |special_date|
        #   # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
        #   JSON.parse(special_date)["start_at_date_part"]
        # end.select { |date| Date.parse(date) >= booking_page.available_booking_start_date }

        # Performance optimization: Preload data only if we detect potential cache misses
        preload_data_for_special_dates if should_preload_data_for_special_dates?

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # Remember to add more connections for activerecord
          # https://www.joshbeckman.org/2020/05/09/cleaning-up-ruby-threads-and-activerecord-connections/
          # if true || Rails.env.test?
            parsed_special_dates.filter_map do |parsed_date_info|
              special_date = parsed_date_info[:date]
              next unless date_in_booking_range?(special_date)

              special_date_start_at = parsed_date_info[:start_at]
              special_date_end_at = parsed_date_info[:end_at]

              available_date = Rails.cache.fetch(cache_key(special_date), expires_in: 12.hours, force: force_update_cache) do
                # use empty string avoid return content is nil
                test_available_booking_date(special_date, special_date_start_at, special_date_end_at) || ""
              end

              available_date if available_date.present?
            end.flatten.uniq
      else
        available_working_dates = schedules[:working_dates].map { |date| Date.parse(date) }
        available_working_dates = available_working_dates.select { |date| date_in_booking_range?(date) }

        # Performance optimization: Preload data only if we detect potential cache misses
        preload_data_for_working_dates(available_working_dates) if should_preload_data_for_working_dates?(available_working_dates)

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # if true || Rails.env.test?
            available_working_dates.filter_map do |date|
              available_date = Rails.cache.fetch(cache_key(date), expires_in: 12.hours, force: force_update_cache) do
                # use empty string avoid return content is nil
                test_available_booking_date(date) || ""
              end

              available_date if available_date.present?
            end.flatten.uniq
          # else
          #   # XXX: Parallel doesn't work properly in test mode,
          #   # some data might be stay in transaction of test thread and would lost in test while using Parallel.
          #   Parallel.map(available_working_dates) do |date|
          #     test_available_booking_date(@booking_options, date)
          #   end.compact
          # end
      end


      [
        schedules,
        available_booking_dates
      ]
    end

    private

    def booking_options
      @booking_options ||= compose(
        BookingOptions::Prioritize,
        booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
      )
    end

    # Performance optimization: Cache parsed JSON data to avoid repeated parsing
    def parsed_special_dates
      @parsed_special_dates ||= special_dates.map do |raw_special_date|
        json_parsed_date = JSON.parse(raw_special_date)
        {
          raw: raw_special_date,
          json: json_parsed_date,
          date: Date.parse(json_parsed_date[START_AT_DATE_PART]),
          start_at: Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{json_parsed_date[START_AT_TIME_PART]}"),
          end_at: Time.zone.parse("#{json_parsed_date[END_AT_DATE_PART]}-#{json_parsed_date[END_AT_TIME_PART]}")
        }
      end
    end

    # Performance optimization: Optimized date range check
    def date_in_booking_range?(date)
      date >= booking_page.available_booking_start_date && date <= booking_page.available_booking_end_date
    end

    # Performance optimization: Smarter cache miss detection for special dates
    def should_preload_data_for_special_dates?
      return true if force_update_cache

      # Quick check: if any of the first few dates don't have cache, likely others don't either
      sample_dates = parsed_special_dates.select { |pd| date_in_booking_range?(pd[:date]) }.first(3)
      return false if sample_dates.empty?

      sample_dates.any? do |parsed_date_info|
        !Rails.cache.exist?(cache_key(parsed_date_info[:date]))
      end
    end

    # Performance optimization: Smarter cache miss detection for working dates
    def should_preload_data_for_working_dates?(working_dates)
      return true if force_update_cache

      # Quick check: if any of the first few dates don't have cache, likely others don't either
      sample_dates = working_dates.first(3)
      return false if sample_dates.empty?

      sample_dates.any? { |date| !Rails.cache.exist?(cache_key(date)) }
    end

    # Performance optimization: Preload data for special dates to avoid N+1 queries during cache miss
    def preload_data_for_special_dates
      return if @cache_data_loaded

      all_dates = parsed_special_dates
        .map { |pd| pd[:date] }
        .select { |date| date_in_booking_range?(date) }

      preload_shared_data(all_dates)
      @cache_data_loaded = true
    end

    # Performance optimization: Preload data for working dates to avoid N+1 queries during cache miss
    def preload_data_for_working_dates(working_dates)
      return if @cache_data_loaded

      all_dates = working_dates.select { |date| date_in_booking_range?(date) }
      preload_shared_data(all_dates)
      @cache_data_loaded = true
    end

    # Shared data preloading logic
    def preload_shared_data(all_dates)
      return if all_dates.empty?

      # Batch load all required data
      @reservation_data = {}
      @custom_schedule_data = {}

      # Performance optimization: Use includes to reduce N+1 queries
      # Batch query all reservation data for dates
      reservations_by_date = shop.reservations
        .includes(:reservation_staffs, :reservation_menus)
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
    end

    # Simplified cache_key - avoid expensive queries when cache exists
    def cache_key(date)
      [
        booking_page,
        date,
        shop,
        booking_option_ids,
        cached_reservation_data(date), # Use cached or simple lookup
        staff_ids,
        cached_custom_schedule_data(date), # Use cached or simple lookup
        cached_business_schedule_last,
        cached_booking_page_special_dates_count,
        cached_booking_page_special_dates_last,
        booking_options_updated_at,
        booking_option_menus_updated_at
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
    def booking_options_menu_ids
      @booking_options_menu_ids ||= booking_options.map(&:menus).flatten.map(&:id).uniq
    end

    def booking_options_total_minutes
      @booking_options_total_minutes ||= booking_options.sum(&:minutes)
    end

    def test_available_booking_date(date, booking_available_start_at = nil, booking_available_end_at = nil)
      time_range_outcome = Reservable::Time.run(shop: shop, booking_page: booking_page, date: date)
      return if time_range_outcome.invalid?

      # Performance optimization: Early exit check
      return if booking_options.any? do |booking_option|
        booking_option.start_time.to_date > date || (booking_option.end_at && booking_option.end_at.to_date < date)
      end

      time_range = time_range_outcome.result
      booking_available_end_at ||= shop_close_at = time_range.last.last
      total_required_time = booking_options_total_minutes # Use cached result

      catch :next_working_date do
        booking_available_start_at ||= shop_open_at = time_range.first.first

        if booking_page.specific_booking_start_times.present?
          booking_page.specific_booking_start_times.each do |start_time_time_part|
            booking_start_at = Time.zone.parse("#{date}-#{start_time_time_part}")
            booking_end_at = booking_start_at.advance(minutes: total_required_time)

            if booking_end_at > booking_available_end_at
              break
            end

            loop_for_reserable_timeslot(
              shop: shop,
              staff_ids: staff_ids,
              booking_page: booking_page,
              booking_options: booking_options, # Use memoized version
              date: date,
              booking_start_at: booking_start_at,
              overbooking_restriction: overbooking_restriction
            ) do
              throw :next_working_date, date.to_s
            end
          end
        else
          loop do
            booking_end_at = booking_available_start_at.advance(minutes: total_required_time)

            if booking_end_at > booking_available_end_at
              break
            end

            loop_for_reserable_timeslot(
              shop: shop,
              staff_ids: staff_ids,
              booking_page: booking_page,
              booking_options: booking_options, # Use memoized version
              date: date,
              booking_start_at: booking_available_start_at,
              overbooking_restriction: overbooking_restriction
            ) do
              throw :next_working_date, date.to_s
            end

            booking_available_start_at = booking_available_start_at.advance(minutes: interval)
          end
        end

        # XXX: When date is not available to book, return nil, otherwise it returns booking_option instance by default
        nil
      end
    end
  end
end
