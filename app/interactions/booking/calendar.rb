module Booking
  class Calendar < ActiveInteraction::Base
    object :shop
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
    integer :interval, default: 30
    boolean :overlap_restriction, default: true

    def execute
      rules = compose(::Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      available_booking_dates =
        if special_dates.present?
          special_dates.map do |special_date|
            # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
            JSON.parse(special_date)["start_at_date_part"]
          end
        else
          booking_options = compose(
            BookingOptions::Prioritize,
            booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
          )

          if Rails.env.test?
            schedules[:working_dates].map do |date|
              test_available_booking_date(booking_options, date)
            end.compact
          else
            # XXX: Parallel doesn't work properly in test mode,
            # some data might be stay in transaction of test thread and would lost in test while using Parallel.
            Parallel.map(schedules[:working_dates]) do |date|
              test_available_booking_date(booking_options, date)
            end.compact
          end
        end

      [
        schedules,
        available_booking_dates
      ]
    end

    private

    def test_available_booking_date(booking_options, date)
      time_range_outcome = Reservable::Time.run(shop: shop, date: date)
      return if time_range_outcome.invalid?

      time_range = time_range_outcome.result
      shop_close_at = time_range.last

      catch :next_working_date do
        booking_options.each do |booking_option|
          # booking_option doesn't sell on that date
          if booking_option.start_time.to_date > Date.parse(date) ||
              booking_option.end_at && booking_option.end_at.to_date < Date.parse(date)
            next
          end

          booking_start_at = shop_open_at = time_range.first

          loop do
            booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

            if booking_end_at > shop_close_at
              break
            end

            base_booking_option_menus = booking_option.booking_option_menus.includes("menu").order("priority").to_a

            if booking_option.menu_restrict_order
              candidate_booking_option_menus_groups = [base_booking_option_menus]
            else
              # XXX: Different menus orders will affect staffs could handle it or not,
              #      so test all the possibility when booking option doesn't restrict menu order
              candidate_booking_option_menus_groups = base_booking_option_menus.permutation(base_booking_option_menus.size)
            end

            candidate_booking_option_menus_groups.each do |candidate_booking_option_menus_group|
              catch :next_menu_group do
                valid_menus = []

                candidate_booking_option_menus_group.each.with_index do |booking_option_menu, index|
                  catch :next_menu do
                    menu = booking_option_menu.menu
                    active_staff_ids = menu.staff_menus.joins(:staff).merge(Staff.active).pluck(:staff_id) & shop.staff_ids
                    required_staffs_number = [menu.min_staffs_number, 1].max # XXX Avoid no manpower menu(min_staffs_number is 0) don't validate staffs
                    menus_count = booking_option.booking_option_menus.count

                    is_first_menu = (index == 0)
                    is_last_menu = (index == (menus_count - 1))

                    if is_first_menu && is_last_menu
                      menu_book_start_at = booking_start_at
                      menu_book_end_at = booking_end_at

                      skip_before_interval_time_validation = false
                      skip_after_interval_time_validation = false
                    elsif is_first_menu
                      menu_book_start_at = booking_start_at
                      menu_book_end_at = booking_start_at.advance(minutes: booking_option_menu.required_time)

                      skip_before_interval_time_validation = false
                      skip_after_interval_time_validation = true
                    elsif is_last_menu
                      menu_book_start_at = booking_end_at.advance(minutes: -booking_option_menu.required_time)
                      menu_book_end_at = booking_end_at
                      skip_before_interval_time_validation = true
                      skip_after_interval_time_validation = false
                    else
                      # middle menu
                      menu_book_start_at = booking_start_at.advance(
                        minutes: booking_option.booking_option_menus.order("priority").where("priority < ?", booking_option_menu.priority).sum(:required_time)
                      )
                      menu_book_end_at = menu_book_start_at.advance(minutes: booking_option_menu.required_time)
                      skip_before_interval_time_validation = true
                      skip_after_interval_time_validation = true
                    end

                    all_possiable_active_staff_ids_groups = active_staff_ids.combination(required_staffs_number).to_a
                    all_possiable_active_staff_ids_groups.each.with_index do |candidate_staff_ids, candidate_staff_index|
                      reserable_outcome = Reservable::Reservation.run(
                        shop: shop,
                        date: date,
                        business_time_range: menu_book_start_at..menu_book_end_at,
                        booking_option_id: booking_option.id,
                        menu_id: menu.id,
                        staff_ids: candidate_staff_ids,
                        overlap_restriction: overlap_restriction,
                        skip_before_interval_time_validation: skip_before_interval_time_validation,
                        skip_after_interval_time_validation: skip_after_interval_time_validation
                      )

                      if reserable_outcome.valid?
                        # Rails.logger.info("====#{date}===#{menu_book_start_at.to_s(:time)}~#{menu_book_end_at.to_s(:time)}=menu #{menu.id}==staff=#{candidate_staff_ids}====is_first_menu #{is_first_menu} === is_last_menu==#{is_last_menu} #{booking_start_at.to_s(:time)}~#{booking_end_at.to_s(:time)}")
                        valid_menus << menu

                        # all menus got staffs to handle
                        if booking_option.menus.count == valid_menus.length
                          throw :next_working_date, date
                        end

                        # XXX: There is staff could handle this menu, so try next menu
                        throw :next_menu
                      else
                        if all_possiable_active_staff_ids_groups.length - 1 == candidate_staff_index
                          # XXX: prior menu no staff could handle, no need to test the behind menus
                          throw :next_menu_group
                        end
                      end
                    end
                  end
                end
              end
            end

            booking_start_at = booking_start_at.advance(minutes: interval)
          end
        end

        # XXX: When date is not available to book, return nil, otherwise it returns booking_option instance by default
        nil
      end
    end
  end
end
