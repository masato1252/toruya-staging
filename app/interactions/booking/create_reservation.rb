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
    boolean :customer_reminder_permission, default: false
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
          customer.update(reminder_permission: customer_reminder_permission)
        else
          # new customer
          customer_outcome = Customers::Create.run(
            user: user,
            customer_last_name: customer_last_name,
            customer_first_name: customer_first_name,
            customer_phonetic_last_name: customer_phonetic_last_name,
            customer_phonetic_first_name: customer_phonetic_first_name,
            customer_phone_number: customer_phone_number,
            customer_email: customer_email
          )

          # XXX: Don't have to find a available reservation, since customer is invalid
          if customer_outcome.invalid?
            errors.merge!(customer_outcome.errors)

            raise ActiveRecord::Rollback
          end

          customer = customer_outcome.result
        end

        catch :booked_reservation do
          unless reservation
            catch :next_working_date do
              loop_for_reserable_spot(
                shop: shop,
                booking_page: booking_page,
                booking_option: booking_option,
                date: date,
                booking_start_at: booking_start_at,
                overbooking_restriction: booking_page.overbooking_restriction
              ) do |valid_menus_spots, staff_states, same_content_reservation|
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
                #
                # staff_states
                # [
                #   {
                #     staff_id: $staff_id
                #     state: pending/accepted
                #   },
                # ]
                #
                # same_content_reservation
                # A reservation active_record object
                if same_content_reservation
                  if reservation_customer = same_content_reservation.reservation_customers.find_by(customer: customer)
                    reservation_customer.update(
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
                  else
                    same_content_reservation.reservation_customers.create(
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
                    same_content_reservation.count_of_customers = same_content_reservation.reservation_customers.active.count
                    same_content_reservation.save
                  end

                  reservation = same_content_reservation
                  throw :booked_reservation
                else
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
                  else
                    errors.merge!(reservation.errors)
                  end
                end
              end
            end
          end
        end

        if customer.persisted? && reservation
          ::ReservationBookingJob.perform_later(customer, reservation, email, phone_number, booking_page, booking_option)
        else
          errors.add(:base, :reservation_something_wrong)
          raise ActiveRecord::Rollback
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
          # XXX: if non attributes changed, no data
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
