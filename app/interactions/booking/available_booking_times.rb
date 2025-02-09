# frozen_string_literal: true
# [redundant]
module Booking
  class AvailableBookingTimes < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    # booking_option_ids
    # ["1"]
    object :booking_page
    array :booking_option_ids
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

    def execute
      return {} if special_dates.blank?

      raw_special_date = special_dates.first
      json_parsed_date = JSON.parse(raw_special_date)
      special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])

      if special_date.today?
        process_available_booking_times(special_date)
      else
        Rails.cache.fetch(cache_key(special_date), expires_in: 12.hours) do
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

            shop.user.booking_options.where(id: booking_option_ids).includes(:menus).order("booking_options.id").each do |booking_option|
              available_booking_times = []
              booking_start_at = special_date_start_at

              # booking_option doesn't sell on that date
              if booking_option.start_time.to_date > special_date || booking_option.end_at && booking_option.end_at.to_date < special_date
                next
              end

              if customer && ticket = customer.active_customer_ticket_of_product(booking_option)
                next if special_date > ticket.expire_at.to_date
              end

              if booking_page.specific_booking_start_times.present?
                booking_page.specific_booking_start_times.each do |start_time_time_part|
                  booking_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{start_time_time_part}")
                  booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

                  if booking_end_at > special_date_end_at
                    break
                  end

                  loop_for_reserable_spot(shop: shop, customer: customer, booking_page: booking_page, booking_option: booking_option, date: booking_start_at.to_date, booking_start_at: booking_start_at, overbooking_restriction: overbooking_restriction) do
                    available_booking_times << booking_start_at

                    available_booking_time_mapping[booking_start_at] ||= []
                    available_booking_time_mapping[booking_start_at] << booking_option.id

                    throw :enough_booking_time if limit && available_booking_times.length >= limit
                  end
                end
              else
                loop do
                  booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

                  if booking_end_at > special_date_end_at
                    break
                  end

                  loop_for_reserable_spot(shop: shop, customer: customer, booking_page: booking_page, booking_option: booking_option, date: booking_start_at.to_date, booking_start_at: booking_start_at, overbooking_restriction: overbooking_restriction) do
                    available_booking_times << booking_start_at

                    available_booking_time_mapping[booking_start_at] ||= []
                    available_booking_time_mapping[booking_start_at] << booking_option.id

                    throw :enough_booking_time if limit && available_booking_times.length >= limit
                  end

                  booking_start_at = booking_start_at.advance(minutes: interval)
                end
              end
            end
          end
        end
      end

      available_booking_time_mapping
    end

    def cache_key(date)
      [
        'available_booking_times',
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

    def booking_options
      @booking_options ||= compose(
        BookingOptions::Prioritize,
        booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
      )
    end

    def booking_options_updated_at
      @booking_options_updated_at ||= booking_options.map(&:updated_at)
    end

    def booking_option_menus_updated_at
      @booking_option_menus_updated_at ||= booking_options.map(&:menus).flatten.uniq.map(&:updated_at)
    end

    def staff_user_ids
      @staff_user_ids ||= shop.staff_users.pluck(:id)
    end
  end
end
