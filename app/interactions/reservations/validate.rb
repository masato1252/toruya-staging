require "reservation_menu_time_calculator"

module Reservations
  class Validate < ActiveInteraction::Base
    ERROR_CAUSES = %i(time_not_enough start_yet is_over lack_staffs)

    object :reservation
    hash :params do
      time :start_time
      time :end_time
      array :customers_list, default: [] do
        hash do
          string :state
        end
      end
      array :menu_staffs_list, default: nil do
        hash do
          integer :menu_id
          integer :menu_required_time
          integer :menu_interval_time
          array :staff_ids, default: [] do
            hash do
              integer :staff_id, default: nil
            end
          end
        end
      end
    end

    def execute
      errors_list = []

      menu_staffs_list = params.delete(:menu_staffs_list)
      customers_list = params.delete(:customers_list)
      number_of_customer = customers_list.size.zero? ? 1 : customers_list.count {|h| h[:state].in?(ReservationCustomer::ACTIVE_STATES) }

      reservation.attributes = params

      reservation.reservation_menus.build(
        Array.wrap(menu_staffs_list).map.with_index do |h, position|
          {
            menu_id: h[:menu_id],
            required_time: h[:menu_required_time],
            position: position
          }
        end
      )

      if menu_staffs_list.present?
        reservation.prepare_time = reservation.start_time - menu_staffs_list.first[:menu_interval_time].minutes
        reservation.ready_time = reservation.end_time + menu_staffs_list.last[:menu_interval_time].minutes

        menu_staffs_list.each.with_index do |h, position|
          time_result = ReservationMenuTimeCalculator.calculate(reservation, reservation.reservation_menus, position)

          skip_before_interval_time_validation = position != 0 # XXX: Only first menu need to validate before interval time
          skip_after_interval_time_validation = (position != (menu_staffs_list.length - 1)) # XXX: Only last menu need to validate after interval time

          outcome = Reservable::Reservation.run(
            shop: reservation.shop,
            date: reservation.start_time.to_date,
            start_time: time_result[:work_start_at],
            end_time: time_result[:work_end_at],
            menu_id: h[:menu_id],
            menu_required_time: h[:menu_required_time],
            staff_ids: h[:staff_ids].map { |hh| hh[:staff_id] }.compact,
            reservation_id: reservation.id,
            number_of_customer: number_of_customer,
            skip_before_interval_time_validation: skip_before_interval_time_validation,
            skip_after_interval_time_validation: skip_after_interval_time_validation
          )

          errors_list << outcome.errors
        end
      else
        outcome = Reservable::Reservation.run(
          shop: reservation.shop,
          date: reservation.start_time.to_date,
          start_time: reservation.start_time,
          end_time: reservation.end_time,
          menu_id: nil,
          menu_required_time: nil,
          staff_ids: [],
          reservation_id: reservation.id,
          number_of_customer: number_of_customer
        )
      end
      errors_with_warnings = {}

      ignored_menu_errors = Rails.env.test? ? [] : [:not_enough_seat, :shop_or_staff_not_enough_ability]

      errors_list.each.with_index do |outcome_errors, menu_index|
        outcome_errors.details.each.with_object({}) do |(error_key, error_details), errors|
          error_details.each do |error_detail|
            error_reason = error_detail[:error]
            option = error_detail.tap { |error| error_detail.delete(:error) }

            if error_reason.in?(ERROR_CAUSES)
              errors_with_warnings[:errors] ||= {}
              errors_with_warnings[:errors][:reservation_form] ||= {}
              error_type = :errors
            else
              errors_with_warnings[:warnings] ||= {}
              errors_with_warnings[:warnings][:reservation_form] ||= {}
              error_type = :warnings
            end

            error_message =
              if error_reason.is_a?(Symbol)
                 outcome_errors.full_message(error_key, outcome_errors.generate_message(error_key, error_reason, option))
              elsif error_reason.to_i.is_a?(Integer)
              else
                errors[error_reason] = outcome_errors.full_message(error_key, error_reason)
              end

            case error_key
            when :menu_id
              next if ignored_menu_errors.include?(error_reason)
              errors_with_warnings[error_type][:reservation_form][:menu_staffs_list] ||= Array.new(menu_staffs_list.length) { Hash[:menu_id, {}] }

              errors_with_warnings[error_type][:reservation_form][:menu_staffs_list][menu_index][:menu_id][error_reason] = error_message
            when :staff_ids
              errors_with_warnings[error_type][:reservation_form][:menu_staffs_list] ||= Array.new(menu_staffs_list.length) { Hash[:menu_id, {}] }
              errors_with_warnings[error_type][:reservation_form][:menu_staffs_list][menu_index][:staff_ids] ||= Array.new(menu_staffs_list[menu_index][:staff_ids].length) { Hash[:staff_id, {}] }
              staff_index = menu_staffs_list[menu_index][:staff_ids].find_index { |staff_h| staff_h[:staff_id] == option[:staff_id] }

              errors_with_warnings[error_type][:reservation_form][:menu_staffs_list][menu_index][:staff_ids][staff_index][:staff_id][error_reason] = error_message
            else
              errors_with_warnings[error_type][:reservation_form][error_key] ||= {}
              errors_with_warnings[error_type][:reservation_form][error_key][error_reason] = error_message
            end
          end
        end
      end

      # XXX: validate multiple menus duplicate case
      if menu_staffs_list.present?
        menu_ids = menu_staffs_list.map { |h| h[:menu_id] }
        duplicate_menu_ids = menu_ids.select { |e| menu_ids.count(e) > 1 }.uniq

        if duplicate_menu_ids.present?
          errors_with_warnings[:errors] ||= {}
          errors_with_warnings[:errors][:reservation_form] ||= {}
          errors_with_warnings[:errors][:reservation_form][:menu_staffs_list] ||= Array.new(menu_staffs_list.length) { Hash[:menu_id, {}] }

          duplicate_menu_ids.each do |duplicate_menu_id|
            duplicate_menu_ids_index = menu_ids.each_index.select {|i| menu_ids[i] == duplicate_menu_id }
            duplicate_menu_ids_index.shift

            duplicate_menu_ids_index.each do |duplicate_menu_id_index|
              errors_with_warnings[:errors][:reservation_form][:menu_staffs_list][duplicate_menu_id_index][:menu_id][:duplicate] = I18n.t("active_interaction.errors.models.reservations/validate.attributes.menu_staffs_list.duplicate")
            end
          end
        end
      end

      # All possible errors and warnings
      # {
      #   errors: {
      #     reservation_form:  {
      #       menu_staffs_list: [
      #         {
      #           menu_id: {
      #             time_not_enough: "time_not_enough",
      #             start_yet: "start_yet",
      #             is_over: "is_over",
      #             lack_staffs: "lack_staffs",
      #             duplicate: "duplicate"
      #           },
      #         }
      #       ]
      #     }
      #   },
      #   warnings: {
      #     reservation_form:  {
      #       date: {
      #         shop_closed: "shop_closed",
      #       },
      #       start_time: {
      #         invalid_time: "invalid_time",
      #         interval_too_short: "interval_too_short"
      #       },
      #       end_time: {
      #         invalid_time: "invalid_time",
      #         interval_too_short: "interval_too_short",
      #       },
      #       menu_staffs_list: [
      #         {
      #           menu_id: {
      #             unschedule_menu: "unschedule_menu",
      #             not_enough_seat: "not_enough_seat",
      #             shop_or_staff_not_enough_ability: "shop_or_staff_not_enough_ability",
      #           },
      #           staff_ids: [
      #             { staff_id: {} },
      #             {
      #               staff_id: {
      #                 ask_for_leave: "ask_for_leave",
      #                 unworking_staff: "unworking_staff",
      #                 not_enough_ability: "not_enough_ability",
      #                 freelancer: "freelancer",
      #                 other_shop: "other_shop",
      #                 overlap_reservations: "overlap_reservations",
      #                 incapacity_menu: "incapacity_menu"
      #               }
      #             }
      #           ]
      #         }
      #       ]
      #     }
      #   }
      # }

      errors_with_warnings
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
