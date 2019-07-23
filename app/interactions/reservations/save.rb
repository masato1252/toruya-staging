require "reservation_menu_time_calculator"

module Reservations
  class Save < ActiveInteraction::Base
    object :reservation
    hash :params do
      time :start_time
      time :end_time
      array :customers_list, default: nil do
        hash do
          integer :customer_id
          string :state
          integer :booking_page_id, default: nil
          integer :booking_option_id, default: nil
          integer :booking_amount_cents,  default: nil
          string :booking_amount_currency, default: nil
          boolean :tax_include, default: nil
          time :booking_at, default: nil
          # details might like
          # {
          #   new_customer_info: { ... },
          # }
          hash :details, strip: false, default: nil
        end
      end
      array :menu_staffs_list do
        hash do
          integer :menu_id
          integer :position, default: nil # TODO: wait position implement
          integer :menu_interval_time
          integer :menu_required_time
          array :staff_ids do
            hash do
              integer :staff_id
              string :state
            end
          end
        end
      end
      string :memo, default: nil
      boolean :with_warnings, default: false
      integer :by_staff_id, default: nil
    end

    def execute
      reservation.transaction do
        menu_staffs_list = params.delete(:menu_staffs_list)
        customers_list = params.delete(:customers_list)
        reservation.attributes = params

        reservation.reservation_menus.destroy_all
        reservation.reservation_menus.build(
          menu_staffs_list.map do |h|
            {
              menu_id: h[:menu_id],
              required_time: h[:menu_required_time],
              position: h[:position],
            }
          end
        )

        reservation.prepare_time = reservation.start_time - menu_staffs_list.first[:menu_interval_time].minutes
        reservation.ready_time = reservation.end_time + menu_staffs_list.last[:menu_interval_time].minutes

        unless reservation.update(params)
          errors.merge!(reservation.errors)
          raise ActiveRecord::Rollback
        end

        if menu_staffs_list.present?
          # TODO: Should keep the original staff's state
          # _ids = [ ... ]
          # update
          # pending notification for staff? mail?
          reservation.reservation_staffs.destroy_all

          # TODO: wait position implement
          menu_staffs_list.each.with_index do |h, i|
            time_result = ReservationMenuTimeCalculator.calculate(reservation, reservation.reservation_menus, h[:position] || i)

            h[:staff_ids].each do |staff_hash|
              reservation.reservation_staffs.create(
                menu_id: h[:menu_id],
                staff_id: staff_hash[:staff_id],
                # If the new staff ids includes current user staff, the staff accepted the reservation automatically
                state: staff_hash[:state] == "accepted" ? "accepted" : (staff_hash[:staff_id].to_s == params[:by_staff_id].to_s ? :accepted : :pending),
                prepare_time: time_result[:prepare_time],
                work_start_at: time_result[:work_start_at],
                work_end_at: time_result[:work_end_at],
                ready_time: time_result[:ready_time]
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

        reservation.accept if reservation.accepted_by_all_staffs? && reservation.accepted_all_customers?
        reservation.count_of_customers = reservation.reservation_customers.active.count
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
