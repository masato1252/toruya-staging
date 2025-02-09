# frozen_string_literal: true

module Booking
  class Calendar < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    object :booking_page
    object :date_range, class: Range
    # booking_option_ids
    # ["1"]
    array :booking_option_ids, default: nil
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

    def execute
      rules = compose(::Shops::WorkingCalendarRules, shop: shop, booking_page: booking_page, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      @booking_options = compose(
        BookingOptions::Prioritize,
        booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
      )
      if special_date_type || special_dates.present?
        # available_working_dates = special_dates.map do |special_date|
        #   # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
        #   JSON.parse(special_date)["start_at_date_part"]
        # end.select { |date| Date.parse(date) >= booking_page.available_booking_start_date }

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # Remember to add more connections for activerecord
          # https://www.joshbeckman.org/2020/05/09/cleaning-up-ruby-threads-and-activerecord-connections/
          # if true || Rails.env.test?
            special_dates.filter_map do |raw_special_date|
              json_parsed_date = JSON.parse(raw_special_date)
              special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])
              next if special_date < booking_page.available_booking_start_date || special_date > booking_page.available_booking_end_date

              special_date_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{json_parsed_date[START_AT_TIME_PART]}")
              special_date_end_at = Time.zone.parse("#{json_parsed_date[END_AT_DATE_PART]}-#{json_parsed_date[END_AT_TIME_PART]}")
              @booking_options.filter_map do |booking_option|
                if customer && ticket = customer.active_customer_ticket_of_product(booking_option)
                  next if special_date > ticket.expire_at.to_date
                end

                available_date = Rails.cache.fetch(cache_key(special_date), expires_in: 12.hours) do
                  # use empty string avoid return content is nil
                  test_available_booking_date(booking_option, special_date, special_date_start_at, special_date_end_at) || ""
                end

                available_date if available_date.present?
              end
            end.flatten.uniq
          # else
          #   # XXX: Parallel doesn't work properly in test mode,
          #   # some data might be stay in transaction of test thread and would lost in test while using Parallel.
          #   Parallel.map(available_working_dates) do |date|
          #     test_available_booking_date(booking_options, date)
          #   end.compact
          # end
      else
        available_working_dates = schedules[:working_dates].map { |date| Date.parse(date) }
        available_working_dates = available_working_dates.select { |date| date >= booking_page.available_booking_start_date && date <= booking_page.available_booking_end_date }

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # if true || Rails.env.test?
            available_working_dates.filter_map do |date|
              @booking_options.filter_map do |booking_option|
                if customer && ticket = customer.active_customer_ticket_of_product(booking_option)
                  next if date > ticket.expire_at.to_date
                end

                available_date = Rails.cache.fetch(cache_key(date), expires_in: 12.hours) do
                  # use empty string avoid return content is nil
                  test_available_booking_date(booking_option, date) || ""
                end

                available_date if available_date.present?
              end
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

    def booking_options_updated_at
      @booking_options_updated_at ||= @booking_options.map(&:updated_at)
    end

    def booking_option_menus_updated_at
      @booking_option_menus_updated_at ||= @booking_options.map(&:menus).flatten.uniq.map(&:updated_at)
    end

    def cache_key(date)
      [
        booking_page,
        date,
        shop,
        shop.reservations.in_date(date).order("updated_at").last,
        CustomSchedule.in_date(date).closed.where(user_id: staff_user_ids).order("updated_at").last,
        BusinessSchedule.where(shop: shop).order("updated_at").last,
        BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).count,
        BookingPageSpecialDate.where(booking_page_id: shop.user.booking_page_ids).order("updated_at").last,
        booking_options_updated_at,
        booking_option_menus_updated_at,
      ]
    end

    def staff_user_ids
      @staff_user_ids ||= shop.staff_users.pluck(:id)
    end

    def test_available_booking_date(booking_option, date, booking_available_start_at = nil, booking_available_end_at = nil)
      time_range_outcome = Reservable::Time.run(shop: shop, booking_page: booking_page, date: date)
      return if time_range_outcome.invalid?

      time_range = time_range_outcome.result
      booking_available_end_at ||= shop_close_at = time_range.last.last

      catch :next_working_date do
        # booking_option doesn't sell on that date
        if !booking_option.sellable_on?(date)
          next
        end

        booking_available_start_at ||= shop_open_at = time_range.first.first

        if booking_page.specific_booking_start_times.present?
          booking_page.specific_booking_start_times.each do |start_time_time_part|
            booking_start_at = Time.zone.parse("#{date}-#{start_time_time_part}")
            booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

            if booking_end_at > booking_available_end_at
              break
            end

            loop_for_reserable_spot(shop: shop, booking_page: booking_page, booking_option: booking_option, date: date, booking_start_at: booking_start_at, overbooking_restriction: overbooking_restriction) do
              throw :next_working_date, date.to_s
            end
          end
        else
          loop do
            booking_end_at = booking_available_start_at.advance(minutes: booking_option.minutes)

            if booking_end_at > booking_available_end_at
              break
            end

            loop_for_reserable_spot(shop: shop, booking_page: booking_page, booking_option: booking_option, date: date, booking_start_at: booking_available_start_at, overbooking_restriction: overbooking_restriction) do
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
