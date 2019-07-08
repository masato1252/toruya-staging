module Booking
  module SharedMethods
    def loop_for_reserable_spot(shop, booking_option, date, booking_start_at, booking_end_at, overlap_restriction)
      booking_option.possible_menus_order_groups.each do |candidate_booking_option_menus_group|
        catch :next_menu_group do
          menu_position = 0
          valid_menus = []

          Rails.logger.info("==")
          Rails.logger.info("==group #{candidate_booking_option_menus_group.map(&:required_time).join(", ")}")
          candidate_booking_option_menus_group.each.with_index do |booking_option_menu, menu_position_index|
            catch :next_menu do
              Rails.logger.info("==menu_id: #{booking_option_menu.menu_id}, required_time: #{booking_option_menu.required_time} menu_position_index: #{menu_position_index}")

              menu = booking_option_menu.menu
              active_staff_ids = menu.staff_menus.order("staff_menus.priority").joins(:staff).merge(Staff.active).pluck(:staff_id) & shop.staff_ids
              required_staffs_number = [menu.min_staffs_number, 1].max # XXX Avoid no manpower menu(min_staffs_number is 0) don't validate staffs
              menus_count = booking_option.booking_option_menus.count

              skip_before_interval_time_validation = menu_position_index != 0 # XXX: Only first menu need to validate before interval time
              skip_after_interval_time_validation = (menu_position_index != (menus_count - 1)) # XXX: Only last menu need to validate after interval time

              menu_book_start_at = booking_start_at.advance(
                minutes: candidate_booking_option_menus_group.slice(0, menu_position_index).sum(&:required_time)
              )
              menu_book_end_at = menu_book_start_at.advance(minutes: booking_option_menu.required_time)

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
                Rails.logger.info("==date: #{date}, #{menu_book_start_at.to_s(:time)}~#{menu_book_end_at.to_s(:time)}, staff: #{candidate_staff_ids}")

                if reserable_outcome.valid?
                  candidate_staff_ids.each do |staff_id|
                    valid_menus << {
                      menu_id: menu.id,
                      position: menu_position,
                      menu_interval_time: menu.interval,
                      menu_required_time: booking_option_menu.required_time,
                      staff_id: staff_id,
                      state: "pending"
                    }
                  end
                  menu_position = menu_position + 1

                  # all menus got staffs to handle
                  if booking_option.menus.count == valid_menus.group_by { |h| h[:menu_id] }.length
                    yield valid_menus
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
    end
  end
end
