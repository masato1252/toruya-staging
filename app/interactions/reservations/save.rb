module Reservations
  class Save < ActiveInteraction::Base
    object :reservation
    hash :params do
      time :start_time
      time :end_time
      array :customers_list, default: nil do
        hash do
          integer :customer_id
          integer :booking_page_id, default: nil
          integer :booking_option_id, default: nil
          integer :booking_amount_cents,  default: nil
          string :booking_amount_currency, default: nil
          boolean :tax_include, default: nil
          time :booking_at, default: nil
          # {
          #   new_customer_info: { ... },
          # }
          hash :details, strip: false, default: nil
        end
      end
      string :memo, default: nil
      boolean :with_warnings
      integer :by_staff_id, default: nil
      # menu_staffs_list
      # [
      #   {
      #     menu_id: menu_id,
      #     menu_interval_time: 10,
      #     menu_required_time: 40,
      #     staff_ids: $staff_ids,
      #     work_start_at: $work_start_time,
      #     work_end_at: $work_end_time
      #   }
      # ]
      array :menu_staffs_list do
        hash do
          integer :menu_id
          integer :menu_interval_time
          array :staff_ids
          time :work_start_at, default: nil
          time :work_end_at, default: nil
        end
      end
      integer :booking_option_id, default: nil
    end

    def execute
      other_staff_ids_changes = []

      reservation.transaction do
        # notify non current staff
        other_staff_ids_changes = params[:menu_staffs_list].map {|h| h[:staff_ids] }.flatten.find_all { |staff_id| staff_id.to_s != params[:by_staff_id].to_s }

        if other_staff_ids_changes.present?
          params.merge!(aasm_state: "pending")
        else
          # staffs create a reservation for themselves
          params.merge!(aasm_state: "reserved")
        end

        menu_staffs_list = params.delete(:menu_staffs_list)
        customers_list = params.delete(:customers_list)
        booking_option_id = params.delete(:booking_option_id)
        reservation.attributes = params

        reservation.reservation_menus.destroy_all
        reservation.reservation_menus.build(
          menu_staffs_list.map.with_index do |h, index|
            {
              menu_id: h[:menu_id],
              required_time: h[:menu_required_time],
              position: index,
            }
          end
        )

        if booking_option_id
          reservation.build_reservation_booking_option(booking_option_id: booking_option_id)
          booking_option = shop.user.booking_options.find(booking_option_id)

          reservation.ready_time = reservation.end_time + booking_option.interval.minutes
          reservation.prepare_time = reservation.start_time - booking_option.interval.minutes
        else
          reservation.prepare_time = reservation.start_time - menu_staffs_list.first[:menu_interval_time].minutes
          reservation.ready_time = reservation.end_time + menu_staffs_list.last[:menu_interval_time].minutes
        end

        unless reservation.update(params)
          errors.merge!(reservation.errors)
          raise ActiveRecord::Rollback
        end

        if menu_staffs_list.present?
          menus_number = menu_staffs_list.length

          menu_staffs_list.each_with_index do |h, index|
            is_first_menu = index == 0
            is_last_menu = index + 1 == menus_number

            h[:staff_ids].each do |staff_id|
              reservation.reservation_staffs.create(
                menu_id: h[:menu_id],
                staff_id: staff_id,
                # If the new staff ids includes current user staff, the staff accepted the reservation automatically
                state: staff_id.to_s == params[:by_staff_id].to_s ? :accepted : :pending,
                prepare_time: is_first_menu ? reservation.prepare_time : (h[:work_start_at] || reservation.prepare_time),
                work_start_at: h[:work_start_at] || reservation.start_time,
                work_end_at: h[:work_end_at] || reservation.end_time,
                ready_time: is_last_menu ? reservation.ready_time : (h[:work_end_at] || reservation.ready_time)
              )
            end
          end
        end

        if customers_list.present?
          reservation.reservation_customers.destroy_all

          customers_list.each do |h|
            reservation.reservation_customers.create(h)
          end
        end

        reservation.accept if reservation.accepted_by_all_staffs?
        reservation.save!

        compose(Reservations::DailyLimitReminder, user: user, reservation: reservation)
        compose(Reservations::TotalLimitReminder, user: user, reservation: reservation)
        reservation
      end
    end

    private

    def user
      @user ||= shop.user
    end

    def shop
      @shop ||= reservation.shop
    end
  end
end
