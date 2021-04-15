# frozen_string_literal: true

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
          decimal :booking_amount_cents,  default: nil
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
          integer :menu_interval_time
          integer :menu_required_time
          array :staff_ids do
            hash do
              integer :staff_id, default: nil
            end
          end
        end
      end
      array :staff_states do
        hash do
          integer :staff_id, default: nil
          string :state
        end
      end
      string :memo, default: nil
      boolean :with_warnings, default: false
      boolean :online, default: false
      integer :by_staff_id, default: nil
    end

    def execute
      reservation.transaction do
        menu_staffs_list = params.delete(:menu_staffs_list)
        customers_list = params.delete(:customers_list)
        staff_states = params.delete(:staff_states)

        reservation.attributes = params
        reservation.user = user
        previous_reservation_customers = reservation.customers.to_a

        reservation.reservation_menus.destroy_all
        reservation.reservation_menus.build(
          menu_staffs_list.map.with_index do |h, position|
            {
              menu_id: h[:menu_id],
              required_time: h[:menu_required_time],
              position: position,
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
          reservation.reservation_staffs.destroy_all

          menu_staffs_list.each.with_index do |h, position|
            time_result = ReservationMenuTimeCalculator.calculate(reservation, reservation.reservation_menus, position)

            h[:staff_ids].each do |staff_hash|
              next if staff_hash[:staff_id].blank?

              staff_state = staff_states.find { |staff_state| staff_state[:staff_id] == staff_hash[:staff_id] }

              reservation.reservation_staffs.create(
                menu_id: h[:menu_id],
                staff_id: staff_hash[:staff_id],
                state: staff_state[:state],
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

        customers_require_notify =
          if reservation.saved_change_to_start_time?
            reservation.customers.reload
          else
            reservation.customers.reload - previous_reservation_customers
          end

        reservation.try_accept
        reservation.count_of_customers = reservation.reservation_customers.active.count
        reservation.save!

        # XXX: Mean this reservation created by a staff, not customer(from booking page)
        if params[:by_staff_id].present? && reservation.start_time >= Time.zone.now
          customers_require_notify.each do |customer|
            ReservationConfirmationJob.perform_later(reservation, customer)
          end
        end

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
