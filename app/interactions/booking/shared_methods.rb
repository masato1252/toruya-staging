# frozen_string_literal: true

require "flow_backtracer"

module Booking
  module SharedMethods
    def loop_for_reserable_timeslot(
      shop:,
      staff_ids:,
      booking_page:,
      booking_options:,
      date:,
      booking_start_at:,
      overbooking_restriction:,
      overlap_restriction: true,
      customer: nil
    )
      return if date < booking_page.available_booking_start_date
        # booking_option doesn't sell on that date
      return if booking_options.any? { |booking_option| !booking_option.sellable_on?(date) }

      menu_ids = booking_options.map(&:menu_ids).flatten.uniq
      # if all menus are not single seat, then check same content reservation
      # otherwise, don't need to check
      if !booking_page.overbooking_restriction || ShopMenu.where(shop_id: shop.id, menu_id: menu_ids).where("max_seat_number > 1").exists?
        if same_content_reservation = matched_same_menus_reservation(
          shop: shop,
          booking_page: booking_page,
          booking_start_at: booking_start_at,
          booking_options: booking_options
        )
          # yield menus, staffs, reservation(if it is existing)
          yield booking_options.map(&:menus).flatten.uniq, same_content_reservation.reservation_staffs.map { |reservation_staff|
            { staff_id: reservation_staff.staff_id, state: reservation_staff.state }
          }, same_content_reservation
        end
      end

      # assume always single one staff handle reservation
      staff_ids = staff_ids.each do |staff_id|
        reserable_outcome = Reservable::ReservationForTimeslot.run(
          shop: shop,
          date: date,
          start_time: booking_start_at,
          total_require_time: booking_options.sum(&:minutes),
          interval_time: booking_options.map(&:menus).flatten.map(&:interval).max,
          menu_ids: booking_options.map(&:menus).flatten.map(&:id).uniq,
          staff_ids: [staff_id],
          overlap_restriction: overlap_restriction,
          overbooking_restriction: overbooking_restriction,
          skip_before_interval_time_validation: false,
          skip_after_interval_time_validation: false,
          online_reservation: booking_options.all?(&:online?),
          booking_page: booking_page
        )

        if reserable_outcome.valid?
          valid_menus = booking_options.map(&:booking_option_menus).flatten.uniq.group_by(&:menu_id).map.with_index do |(menu_id, booking_option_menus), index|
            {
              menu_id: menu_id,
              position: index,
              menu_interval_time: booking_option_menus.first.menu.interval,
              menu_required_time: booking_option_menus.sum(&:required_time),
              staff_ids: [{ staff_id: staff_id }],
            }
          end

          yield valid_menus, [{ staff_id: staff_id, state: "pending" }], nil
          # TODO: validate multiple staffs still only pick one to book
          break
        end
      end
    end

    # date: Date object
    def loop_for_reserable_spot(shop:, booking_page:, booking_option:, date:, booking_start_at:, overbooking_restriction:, overlap_restriction: true, customer: nil)
      # staffs are unavailable all days
      @unactive_staff_ids ||= {}

      return if date < booking_page.available_booking_start_date

      # TODO: [Multiple booking option] for support multiple booking options, use menus to match
      if same_content_reservation = matched_same_content_reservation(shop: shop, booking_page: booking_page, booking_start_at: booking_start_at, booking_option: booking_option)
        # yield menus, staffs, reservation(if it is existing)
        yield booking_option.menus, same_content_reservation.reservation_staffs.map { |reservation_staff|
          { staff_id: reservation_staff.staff_id, state: reservation_staff.state }
        }, same_content_reservation
      end

      # TODO: [Multiple booking option] for support multiple booking options, use all booking options menus to match
      # Make it simpler, since we assume all staffs could handle it, no order issue, just check slot for total time
      booking_option.possible_menus_order_groups.each do |candidate_booking_option_menus_group|
        catch :next_menu_group do
          menu_position = 0
          valid_menus = []

          Rails.logger.debug("==")
          Rails.logger.debug("==group #{candidate_booking_option_menus_group.map(&:required_time).join(", ")}")
          candidate_booking_option_menus_group.each.with_index do |booking_option_menu, menu_position_index|
            catch :next_menu do
              Rails.logger.debug("==menu_id: #{booking_option_menu.menu_id}, required_time: #{booking_option_menu.required_time} menu_position_index: #{menu_position_index}")

              menu = booking_option_menu.menu
              active_staff_ids = menu.staff_menus.order("staff_menus.priority").joins(:staff).merge(Staff.active).pluck(:staff_id) & shop.user.staffs.map(&:id)
              active_staff_ids = active_staff_ids - Array.wrap(@unactive_staff_ids[date])

              required_staffs_number = [menu.min_staffs_number, 1].max # XXX Avoid no manpower menu(min_staffs_number is 0) don't validate staffs
              menus_count = booking_option.booking_option_menus.count

              skip_before_interval_time_validation = menu_position_index != 0 # XXX: Only first menu need to validate before interval time
              skip_after_interval_time_validation = (menu_position_index != (menus_count - 1)) # XXX: Only last menu need to validate after interval time

              menu_book_start_at = booking_start_at.advance(
                minutes: candidate_booking_option_menus_group.slice(0, menu_position_index).sum(&:required_time)
              )
              menu_book_end_at = menu_book_start_at.advance(minutes: booking_option_menu.required_time)

              all_possible_active_staff_ids_groups = active_staff_ids.combination(required_staffs_number).to_a

              # XXX: not enough required staffs
              if all_possible_active_staff_ids_groups.blank?
                ::FlowBacktracer.track(:debug_booking_page) { { "not enough required staffs": [all_possible_active_staff_ids_groups, active_staff_ids.combination(required_staffs_number).to_a]  } }

                throw :next_working_date
              end

              all_possible_active_staff_ids_groups.each.with_index do |candidate_staff_ids, candidate_staff_index|
                if (Array.wrap(@unactive_staff_ids[date]) & candidate_staff_ids).length > 0
                  next
                end

                reserable_outcome = Reservable::Reservation.run(
                  shop: shop,
                  date: date,
                  start_time: menu_book_start_at,
                  end_time: menu_book_end_at,
                  menu_id: menu.id,
                  menu_required_time: booking_option_menu.required_time,
                  staff_ids: candidate_staff_ids,
                  overlap_restriction: overlap_restriction,
                  overbooking_restriction: overbooking_restriction,
                  skip_before_interval_time_validation: skip_before_interval_time_validation,
                  skip_after_interval_time_validation: skip_after_interval_time_validation,
                  online_reservation: booking_option.online?,
                  booking_page: booking_page
                )

                Rails.logger.debug("==date: #{date}, #{menu_book_start_at.to_fs(:time)}~#{menu_book_end_at.to_fs(:time)}, staff: #{candidate_staff_ids}, overlap_restriction: #{overlap_restriction}, overbooking_restriction: #{overbooking_restriction}, skip_before_interval_time_validation: #{skip_before_interval_time_validation}, skip_after_interval_time_validation: #{skip_after_interval_time_validation} ")

                if reserable_outcome.valid?
                  valid_menus << {
                    menu_id: menu.id,
                    position: menu_position,
                    menu_interval_time: menu.interval,
                    menu_required_time: booking_option_menu.required_time,
                    staff_ids: candidate_staff_ids.map { |staff_id| { staff_id: staff_id } },
                  }
                  menu_position = menu_position + 1

                  # all menus got staffs to handle
                  if booking_option.menus.count == valid_menus.length
                    Rails.logger.debug("[GOOD]==date: #{date}, #{menu_book_start_at.to_fs(:time)}~#{menu_book_end_at.to_fs(:time)}, staff: #{candidate_staff_ids}, overlap_restriction: #{overlap_restriction}, overbooking_restriction: #{overbooking_restriction}, skip_before_interval_time_validation: #{skip_before_interval_time_validation}, skip_after_interval_time_validation: #{skip_after_interval_time_validation} ")
                    yield valid_menus, candidate_staff_ids.map { |staff_id| { staff_id: staff_id, state: "pending" } }, nil
                  end

                  # XXX: There is staff could handle this menu, so try next menu
                  throw :next_menu
                else
                  # reserable_outcome.errors.details
                  # {:staff_ids=>[{:error=>:ask_for_leave, :staff_id=>44, :menu_id=>186}]}
                  if reserable_outcome.errors.details[:staff_ids].present? &&
                      (reserable_outcome.errors.details.values.flatten.map{|h| h[:error]} & [:freelancer, :unworking_staff, :other_shop, :ask_for_leave]).length > 0
                    reserable_outcome.errors.details[:staff_ids].each do |error|
                      # error => {:error=>:freelancer, :staff_id=>36, :menu_id=>186}
                      case error[:error]
                      when :freelancer
                        # freelancer(without business schedule) but without open schedule today
                        if !CustomSchedule.opened.where(staff_id: error[:staff_id]).
                            where("start_time >= ? and end_time <= ?", date.beginning_of_day, date.end_of_day).exists?
                          @unactive_staff_ids[date] ||= []
                          @unactive_staff_ids[date] << error[:staff_id]
                        end
                      when :ask_for_leave
                        ::FlowBacktracer.track(:debug_booking_page) { { "ask_for_leave #{date}": { error: error, date: date }} }
                        # Staff(User) ask for leave whole day, for performance doesn't need to check others
                        if CustomSchedule.closed.where(
                            user_id: Staff.find(error[:staff_id]).staff_account.user.staff_accounts.pluck(:user_id)
                        ).where("start_time = ? and end_time = ?", date.beginning_of_day, date.end_of_day.change(sec: 0)).exists?
                          ::FlowBacktracer.track(:debug_booking_page) { { "#{date} ask_for_leave": { leave_whole_day: true, date: date, staff: error[:staff_id] } } }
                          @unactive_staff_ids[date] ||= []
                          @unactive_staff_ids[date] << error[:staff_id]
                        end
                      when :other_shop, :unworking_staff
                        @unactive_staff_ids[date] ||= []
                        @unactive_staff_ids[date] << error[:staff_id]
                      end
                    end
                  end

                  if reserable_outcome.errors.details[:menu_id].present? &&
                      (reserable_outcome.errors.details.values.flatten.map{|h| h[:error]} & [:unschedule_menu]).length > 0
                    reserable_outcome.errors.details[:menu_id].each do |error|
                      case error[:error]
                      when :unschedule_menu
                        if reservation_setting = Menu.find(error[:menu_id]).reservation_setting
                          if (reservation_setting.days_of_week.present? && reservation_setting.days_of_week.exclude?(date.wday.to_s)) ||
                              (reservation_setting.nth_of_week.present? && reservation_setting.nth_of_week != date.week_of_month) ||
                              (reservation_setting.day.present? && reservation_setting.day != date.day)
                            ::FlowBacktracer.track(:debug_booking_page) { { "unschedule_menu": "#{reservation_setting.inspect}" } }
                            throw :next_working_date
                          end
                        end
                      end
                    end
                  end

                  Rails.logger.debug("==error #{reserable_outcome.errors.full_messages.join(", ")} #{reserable_outcome.errors.details.inspect}")

                  ::FlowBacktracer.track(:debug_booking_page) { { "final_error #{date}": "==date: #{date}, #{menu_book_start_at.to_fs(:time)}~#{menu_book_end_at.to_fs(:time)}, staff: #{candidate_staff_ids}, overlap_restriction: #{overlap_restriction}, overbooking_restriction: #{overbooking_restriction}, skip_before_interval_time_validation: #{skip_before_interval_time_validation}, skip_after_interval_time_validation: #{skip_after_interval_time_validation} ==error #{reserable_outcome.errors.full_messages.join(", ")} #{reserable_outcome.errors.details.inspect}" } }


                  if all_possible_active_staff_ids_groups.length - 1 == candidate_staff_index
                    # XXX: prior menu no staff could handle, no need to test the behind menus
                    throw :next_menu_group
                  end
                end
              end
            end
          end
        end
      end
    end

    def matched_same_content_reservation(shop:, booking_page:, booking_start_at:, booking_option:)
      reservation = nil

      Reservation.uncanceled.where(
        shop: shop,
        start_time: booking_start_at,
      ).each do |same_time_reservation|
        same_time_reservation.with_lock do
          if booking_option.menu_restrict_order
            if booking_option.menu_relations.order("priority").pluck(:menu_id, :required_time) != same_time_reservation.reservation_menus.pluck(:menu_id, :required_time)
              next
            end
          else
            if booking_option.menu_relations.order("priority").pluck(:menu_id, :required_time).sort != same_time_reservation.reservation_menus.pluck(:menu_id, :required_time).sort
              next
            end
          end

          menus_count = same_time_reservation.reservation_menus.count
          select_sql = <<-SELECT_SQL
              reservation_staffs.menu_id,
              max(work_start_at) as work_start_at,
              max(work_end_at) as work_end_at,
              array_agg(staff_id) as staff_ids,
              max(reservation_menus.position) as position
          SELECT_SQL

          same_time_reservation
            .reservation_staffs
            .order_by_menu_position
            .select(select_sql).group("reservation_staffs.menu_id, reservation_menus.position").each.with_index do |reservation_staff_properties, index|
            # [
            #   <ReservationStaff:0x00007fcd262ba278> {
            #     "id" => nil,
            #     "work_start_at" => Fri, 10 Apr 2015 13:00:00 JST +09:00,
            #     "work_end_at" => Fri, 10 Apr 2015 15:30:00 JST +09:00,
            #     "staff_ids" => [
            #       2
            #     ],
            #     "menu_id" => 1,
            #     "position" => 1
            #   }
            # ]
            skip_before_interval_time_validation = index != 0 # XXX: Only first menu need to validate before interval time
            skip_after_interval_time_validation = (index != (menus_count - 1)) # XXX: Only last menu need to validate after interval time

            present_reservable_reservation_outcome = Reservable::Reservation.run(
              shop: shop,
              date: booking_start_at.to_date,
              start_time: reservation_staff_properties.work_start_at,
              end_time: reservation_staff_properties.work_end_at,
              menu_id: reservation_staff_properties.menu_id,
              menu_required_time: menu_required_time(booking_option, reservation_staff_properties.menu_id),
              staff_ids: reservation_staff_properties.staff_ids,
              reservation_id: same_time_reservation.id,
              number_of_customer: same_time_reservation.count_of_customers + 1,
              overbooking_restriction: booking_page.overbooking_restriction,
              skip_before_interval_time_validation: skip_before_interval_time_validation,
              skip_after_interval_time_validation: skip_after_interval_time_validation,
              online_reservation: booking_option.online?,
              booking_page: booking_page
            )

            if present_reservable_reservation_outcome.valid?
              reservation = same_time_reservation
              break
            else
              next
            end
          end
        end
      end

      reservation
    end

    def matched_same_menus_reservation(shop:, booking_page:, booking_start_at:, booking_options:)
      reservation = nil

      Reservation.uncanceled.where(
        shop: shop,
        start_time: booking_start_at,
      ).each do |same_time_reservation|
        same_time_reservation.with_lock do
          if booking_options.map(&:menus).flatten.pluck(:id).uniq.sort != same_time_reservation.reservation_menus.pluck(:menu_id).uniq.sort
            next
          end

          present_reservable_reservation_outcome = Reservable::ReservationForTimeslot.run(
            shop: shop,
            date: booking_start_at.to_date,
            start_time: booking_start_at,
            total_require_time: booking_options.sum(&:minutes),
            interval_time: booking_options.map(&:menus).flatten.map(&:interval).max,
            menu_ids: booking_options.map(&:menus).flatten.map(&:id).uniq,
            staff_ids: same_time_reservation.reservation_staffs.map(&:staff_id),
            reservation_id: same_time_reservation.id,
            number_of_customer: same_time_reservation.count_of_customers + 1,
            overbooking_restriction: booking_page.overbooking_restriction,
            skip_before_interval_time_validation: true,
            skip_after_interval_time_validation: true,
            online_reservation: booking_options.any?(&:online?),
            booking_page: booking_page
          )

          if present_reservable_reservation_outcome.valid?
            reservation = same_time_reservation
            break
          else
            next
          end
        end
      end

      reservation
    end

    def menu_required_time(booking_option, menu_id)
      @menu_required_time ||= {}
      @menu_required_time[booking_option.id] ||= {}
      @menu_required_time[booking_option.id][menu_id] ||= booking_option.booking_option_menus.where(menu_id: menu_id).first.required_time
    end
  end
end
