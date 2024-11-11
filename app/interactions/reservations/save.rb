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
          array :booking_option_ids, default: []
          decimal :booking_amount_cents,  default: nil
          string :booking_amount_currency, default: nil
          boolean :tax_include, default: nil
          time :booking_at, default: nil
          # details might like
          # {
          #   new_customer_info: { ... },
          # }
          hash :details, strip: false, default: nil
          integer :sale_page_id, default: nil
          integer :function_access_id, default: nil
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
      string :meeting_url, default: nil
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
          reservation_customers = reservation.reservation_customers.to_a

          customers_list.each do |customer_data|
            if reservation_customer = reservation_customers.find { |reservation_customer| reservation_customer.customer_id == customer_data[:customer_id] }
              if reservation_customer.update(customer_data)

                previous_state, current_state = reservation_customer.previous_changes[:state]
                if current_state == 'accepted'
                  ReservationConfirmationJob.perform_later(reservation, reservation_customer.customer)
                end
              end
            else
              ReservationCustomers::Create.run(reservation: reservation, customer_data: customer_data)
            end
          end

          customer_ids = customers_list.map { |customer| customer[:customer_id] }
          reservation_customers.each do |reservation_customer|
            if customer_ids.exclude?(reservation_customer.customer_id)
              reservation_customer.destroy
            end
          end
        end

        if reservation.saved_change_to_start_time?
          reservation.reservation_customers.each do |reservation_customer|

            custom_messages_scope = if reservation_customer.booking_page_id.present?
              CustomMessage.scenario_of(reservation_customer.booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER)
            else
              CustomMessage.scenario_of(reservation.shop, CustomMessages::Customers::Template::SHOP_CUSTOM_REMINDER)
            end

            custom_messages_scope.where.not(before_minutes: nil).each do |custom_message|
              delivery_time = reservation.start_time.advance(minutes: -custom_message.before_minutes)
              next if Time.current > delivery_time

              Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
                schedule_at: delivery_time,
                custom_message: custom_message,
                reservation: reservation,
                receiver: reservation_customer.customer
              )
            end

            custom_messages_scope.where.not(after_days: nil).each do |custom_message|
              delivery_time = reservation.start_time.advance(days: custom_message.after_days)
              next if Time.current > delivery_time

              Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
                schedule_at: delivery_time,
                custom_message: custom_message,
                reservation: reservation,
                receiver: reservation_customer.customer
              )
            end
          end
        end


        reservation.count_of_customers = reservation.reservation_customers.active.count
        reservation.save!

        # All staffs accepted and only one pending/accepted customers
        if reservation.reservation_staffs.map(&:state).all?("accepted")
          compose(
            Reservations::Accept,
            current_staff: reservation.staffs.first,
            reservation: reservation
          )
        end
      end

      compose(Users::UpdateCustomerLatestActivityAt, user: user)
      ::RichMenus::BusinessSwitchRichMenu.run(owner: user)

      reservation
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
