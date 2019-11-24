require "hash_deep_diff"

module Booking
  class CreateReservation < ActiveInteraction::Base
    include ::Booking::SharedMethods

    integer :booking_page_id
    integer :booking_option_id
    time :booking_start_at
    string :customer_last_name, default: nil
    string :customer_first_name, default: nil
    string :customer_phonetic_last_name, default: nil
    string :customer_phonetic_first_name, default: nil
    string :customer_phone_number, default: nil
    string :customer_email, default: nil
    # customer_info format might like
    # {
    #   id: customer_with_google_contact&.id,
    #   first_name: customer_with_google_contact&.first_name,
    #   last_name: customer_with_google_contact&.last_name,
    #   phonetic_first_name: customer_with_google_contact&.phonetic_first_name,
    #   phonetic_last_name: customer_with_google_contact&.phonetic_last_name,
    #   phone_number: params[:customer_phone_number] || cookies[:booking_customer_phone_number],
    #   phone_numbers: customer_with_google_contact&.phone_numbers&.map { |phone| phone.value.gsub(/[^0-9]/, '') },
    #   email: customer_with_google_contact&.primary_email&.value&.address,
    #   emails: customer_with_google_contact&.emails&.map { |email| email.value.address },
    #   simple_address: customer_with_google_contact&.address,
    #   full_address: customer_with_google_contact&.display_address,
    #   address_details: customer_with_google_contact&.primary_address&.value,
    #   original_address_details: customer_with_google_contact&.primary_address&.value
    # }
    hash :customer_info, strip: false, default: nil do
      integer :id, default: nil
      string :last_name, default: nil
      string :first_name, default: nil
      string :phonetic_last_name, default: nil
      string :phonetic_first_name, default: nil
      string :phone_number, default: nil
      array :phone_numbers, default: nil do
        string
      end

      string :email, default: nil
      array :emails, default: nil do
        string
      end

      string :simple_address, default: nil
      string :full_address, default: nil
      hash :address_details, default: nil, strip: false do
        string :formatted_address, default: nil
        boolean :primary, default: nil
        string :postcode, default: nil
        string :city, default: nil
        string :region, default: nil
        string :street, default: nil
      end

      hash :original_address_details, default: nil, strip: false do
        string :formatted_address, default: nil
        boolean :primary, default: nil
        string :postcode, default: nil
        string :city, default: nil
        string :region, default: nil
        string :street, default: nil
      end
    end
    # present_customer_info and customer_info format is the same
    hash :present_customer_info, strip: false, default: nil

    validate :validates_enough_customer_data

    def execute
      # Get customer if customer_info exists is existing customer use exist customer otherwise
      # create a new customer and save new customer raw data or compare with original_customer_info to reservation
      #
      # find reservation with the same booking option and booking start time
      # if reservation exist(might be multiple reservation?)
      #   lock the reservation
      #   Use Reservable::Reservation use the same info but add one more customer to test is it available
      #
      #   if new customer is available for existing reservation
      #      add it to the existing reservation
      #   else
      #     if booking page is allow overlap, then try to create a new reservation, like reservation doesn't exist case
      #     if not allow overlap, show error message
      #
      # else reservation doens't exist
      #  use Booking::SharedMethods loop_for_reserable_spot to find the available staffs 

      Reservation.transaction do
        reservation = nil

        if customer_info&.compact.present?
          # regular customer
          customer = user.customers.find(customer_info["id"])
        else
          # new customer
          begin
            customer_info_hash = {
              last_name: customer_last_name,
              first_name: customer_first_name,
              phonetic_last_name: customer_phonetic_last_name,
              phonetic_first_name: customer_phonetic_first_name,
              email_types: "mobile",
              emails: [{ type: "mobile", value: { address: customer_email }, primary: true }],
              phone_numbers: [{ type: "mobile", value: customer_phone_number, primary: true }]
            }

            customer = user.customers.new(customer_info_hash)
            google_user = user.google_user
            result = google_user.create_contact(customer.google_contact_attributes)
            customer.google_contact_id = result.id
            customer.google_uid = user.uid
            customer.save
          rescue => e
            Rollbar.error(e)
            errors.add(:base, :google_down)
          end
        end

        Reservation.where(
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
                date: date,
                start_time: reservation_staff_properties.work_start_at,
                end_time: reservation_staff_properties.work_end_at,
                menu_id: reservation_staff_properties.menu_id,
                menu_required_time: booking_option.booking_option_menus.find_by(menu_id: reservation_staff_properties.menu_id).required_time,
                staff_ids: reservation_staff_properties.staff_ids,
                reservation_id: same_time_reservation.id,
                number_of_customer: same_time_reservation.count_of_customers + 1,
                overbooking_restriction: booking_page.overbooking_restriction,
                skip_before_interval_time_validation: skip_before_interval_time_validation,
                skip_after_interval_time_validation: skip_after_interval_time_validation
              )

              if present_reservable_reservation_outcome.valid?
                unless same_time_reservation.reservation_customers.where(customer: customer).exists?
                  same_time_reservation.reservation_customers.create(
                    customer_id: customer.id,
                    state: "pending",
                    booking_page_id: booking_page.id,
                    booking_option_id: booking_option_id,
                    booking_amount_cents: booking_option.amount.fractional,
                    booking_amount_currency: booking_option.amount.currency.to_s,
                    tax_include: booking_option.tax_include,
                    booking_at: Time.current,
                    details: {
                      new_customer_info: new_customer_info.attributes.compact,
                    }
                  )
                  same_time_reservation.count_of_customers = same_time_reservation.reservation_customers.active.count
                  same_time_reservation.save
                end

                reservation = same_time_reservation
                break
              else
                next
              end
            end
          end
        end

        catch :booked_reservation do
          unless reservation
            loop_for_reserable_spot(
              shop,
              booking_option,
              date,
              booking_start_at,
              booking_end_at,
              booking_page.overbooking_restriction
            ) do |valid_menus_spots, staff_states|
              # valid_menus_spots likes
              # [
              #   {
              #     menu_id: menu_id,
              #     position: $position,
              #     menu_interval_time: 10,
              #     menu_required_time: 60,
              #     staff_ids: [
              #       {
              #         staff_id: $staff_id
              #         state: pending/accepted
              #       },
              #       ...
              #     ],
              #   }
              # ]
              # staff_states
              # [
              #   {
              #     staff_id: $staff_id
              #     state: pending/accepted
              #   },
              # ]
              reservation_outcome = Reservations::Save.run(
                reservation: shop.reservations.new,
                params: {
                  start_time: booking_start_at,
                  end_time: booking_end_at,
                  customers_list: [{
                    customer_id: customer.id,
                    state: "pending",
                    booking_page_id: booking_page.id,
                    booking_option_id: booking_option_id,
                    booking_amount_cents: booking_option.amount.fractional,
                    booking_amount_currency: booking_option.amount.currency.to_s,
                    tax_include: booking_option.tax_include,
                    booking_at: Time.current,
                    details: {
                      new_customer_info: new_customer_info.attributes.compact,
                    }
                  }],
                  menu_staffs_list: valid_menus_spots,
                  staff_states: staff_states,
                  memo: "",
                  with_warnings: false
                }
              )

              if reservation_outcome.valid?
                reservation = reservation_outcome.result
                throw :booked_reservation
              end
            end
          end
        end

        if customer.persisted? && reservation
          # XXX: Use the phone_number using at booking time
          if phone_number.present?
            ::Bookings::CustomerSmsNotificationJob.perform_later(customer, reservation, phone_number)
          end

          # XXX: Use the email using at booking time
          if email.present?
            BookingMailer.with(
              customer: customer,
              reservation: reservation,
              booking_page: booking_page,
              booking_option: booking_option,
              email: email
            ).customer_reservation_notification.deliver_later
          end

          BookingMailer.with(
            customer: customer,
            reservation: reservation,
            booking_page: booking_page,
            booking_option: booking_option,
          ).shop_owner_reservation_booked_notification.deliver_later
        end

        {
          customer: customer,
          reservation: reservation
        }
      end
    end

    private

    def user
      @user ||= booking_page.user
    end

    def shop
      @shop ||= booking_page.shop
    end

    def booking_page
      @booking_page ||= BookingPage.find(booking_page_id)
    end

    def booking_option
      @booking_option ||= user.booking_options.find(booking_option_id)
    end

    def booking_end_at
      @booking_end_at ||= booking_start_at.advance(minutes: booking_option.minutes)
    end

    def date
      @date ||= booking_start_at.to_date
    end

    def validates_enough_customer_data
      if customer_info&.compact.blank?
        if !customer_last_name ||
          !customer_first_name ||
          !customer_phonetic_last_name ||
          !customer_phonetic_first_name ||
          !customer_phone_number ||
          !customer_email
          errors.add(:customer_info, :not_enough_customer_data)
        end
      end
    end

    def new_customer_info
      @new_customer_info ||=
        if customer_info&.compact.present?
          # TODO: if non attributes changed, no data
          Booking::CustomerInfo.new(present_customer_info.changed_deep_diff(customer_info))
        else
          Booking::CustomerInfo.new(
            last_name: customer_last_name,
            first_name: customer_first_name,
            phonetic_last_name: customer_phonetic_last_name,
            phonetic_first_name: customer_phonetic_first_name,
            phone_number: customer_phone_number,
            email: customer_email
          )
        end
    end

    def phone_number
      if customer_info&.compact.present?
        customer_info["phone_number"]
      else
        customer_phone_number
      end
    end

    def email
      if customer_info&.compact.present?
        customer_info["email"]
      else
        customer_email
      end
    end
  end
end
