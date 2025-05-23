# frozen_string_literal: true

require "hash_deep_diff"

module Booking
  class CreateReservationForTimeslot < ActiveInteraction::Base
    include ::Booking::SharedMethods

    integer :booking_page_id
    array :booking_option_ids
    array :staff_ids
    time :booking_start_at
    string :customer_last_name, default: nil
    string :customer_first_name, default: nil
    string :customer_phonetic_last_name, default: nil
    string :customer_phonetic_first_name, default: nil
    string :customer_phone_number, default: nil
    string :customer_email, default: nil
    string :social_user_id, default: nil
    string :stripe_token, default: nil
    string :square_token, default: nil
    string :square_location_id, default: nil
    string :payment_intent_id, default: nil
    boolean :customer_reminder_permission, default: true
    # customer_info format might like
    # {
    #   id: customer_with_google_contact&.id,
    #   first_name: customer_with_google_contact&.first_name,
    #   last_name: customer_with_google_contact&.last_name,
    #   phonetic_first_name: customer_with_google_contact&.phonetic_first_name,
    #   phonetic_last_name: customer_with_google_contact&.phonetic_last_name,
    #   phone_number: params[:customer_phone_number]
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
      array :phone_numbers, default: nil

      string :email, default: nil
      array :emails, default: nil

      string :simple_address, default: nil
      string :full_address, default: nil
      hash :address_details, default: nil, strip: false do
        string :zip_code, default: nil
        string :city, default: nil
        string :region, default: nil
        string :street1, default: nil
        string :street2, default: nil
      end

      hash :original_address_details, default: nil, strip: false do
        string :formatted_address, default: nil
        boolean :primary, default: nil
        string :zip_code, default: nil
        string :city, default: nil
        string :region, default: nil
        string :street1, default: nil
        string :street2, default: nil
      end
    end
    # present_customer_info and customer_info format is the same
    hash :present_customer_info, strip: false, default: nil
    integer :sale_page_id, default: nil

    integer :function_access_id, default: nil
    array :survey_answers, default: nil

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
      # else reservation doesn't exist
      #  use Booking::SharedMethods loop_for_reserable_spot to find the available staffs

      Reservation.transaction do
        ActiveRecord::Base.with_advisory_lock("customer_booking_in_user_#{user.id}") do
          reservation = nil
          customer = nil

          if booking_page && has_basic_customer_info?
            customer = Booking::FindCustomer.run!(
              booking_page: booking_page,
              first_name: customer_first_name,
              last_name: customer_last_name,
              phone_number: customer_phone_number,
              email: customer_email
            )
          end

          if !customer && customer_info&.compact.present? && customer_info["id"]
            # regular customer
            customer = user.customers.find(customer_info["id"])
          end

          if social_customer&.is_owner?
            if customer
              if has_basic_customer_info?
                customer = compose(Customers::Store,
                  user: user,
                  current_user: user,
                  params: {
                    id: customer.id.to_s,
                    last_name: customer_last_name,
                    first_name: customer_first_name,
                    phonetic_last_name: customer_phonetic_last_name,
                    phonetic_first_name: customer_phonetic_first_name,
                    phone_numbers_details: [{ type: "mobile", value: customer_phone_number.presence || customer.mobile_phone_number }],
                    emails_details: [{ type: "mobile", value: customer_email.presence || customer.email }],
                  }.compact
                )
              end
              # Trying to booking for themself and put the shop owner customer data
            elsif has_basic_customer_info?
              # Booking for their customer, this is new customer, the name doesn't match
              customer = create_new_customer
            else
              # Trying to booking for themself, no customer data
              customer = social_customer&.customer
            end
          else
            # regular customer come
            if customer ||= social_customer&.customer
              customer = compose(Customers::Store,
                user: user,
                current_user: user,
                params: {
                  id: customer.id.to_s,
                  last_name: customer_last_name,
                  first_name: customer_first_name,
                  phonetic_last_name: customer_phonetic_last_name,
                  phonetic_first_name: customer_phonetic_first_name,
                  phone_numbers_details: [{ type: "mobile", value: customer_phone_number.presence || customer.mobile_phone_number }],
                  emails_details: [{ type: "mobile", value: customer_email.presence || customer.email }],
                }.compact
              )
            else
              # new customer
              customer = create_new_customer
            end
          end

          if social_customer && !social_customer.is_owner
            social_customer.update!(customer_id: customer.id)
          end

          if !customer.had_address? && customer_info && customer_info[:address_details].present?
            customer.address_details = customer_info[:address_details]
          end

          customer.assign_attributes(
            reminder_permission: customer_reminder_permission,
            updated_at: Time.current
          )

          customer.save

          catch :booked_reservation do
            unless reservation
              loop_for_reserable_timeslot(
                shop: shop,
                staff_ids: staff_ids,
                booking_page: booking_page,
                booking_options: booking_options,
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
                      booking_option_ids: booking_option_ids,
                      booking_amount_cents: booking_options.sum(&:amount).fractional,
                      booking_amount_currency: booking_options.sum(&:amount).currency.to_s,
                      tax_include: booking_options.first.tax_include,
                      booking_at: Time.current,
                      details: {
                        new_customer_info: new_customer_info.attributes.compact,
                      },
                      sale_page_id: reservation_customer.sale_page_id.presence || sale_page_id
                    )
                  else
                    ReservationCustomers::Create.run(
                      reservation: same_content_reservation,
                      customer_data: {
                        customer_id: customer.id,
                        state: "pending",
                        booking_page_id: booking_page.id,
                        booking_option_ids: booking_option_ids,
                        booking_amount_cents: booking_options.sum(&:amount).fractional,
                        booking_amount_currency: booking_options.sum(&:amount).currency.to_s,
                        tax_include: booking_options.first.tax_include,
                        booking_at: Time.current,
                        details: {
                          new_customer_info: new_customer_info.attributes.compact,
                        },
                        sale_page_id: sale_page_id
                      })
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
                        booking_option_ids: booking_option_ids,
                        booking_amount_cents: booking_options.sum(0, &:amount).fractional,
                        booking_amount_currency: booking_options.sum(0, &:amount).currency.to_s,
                        tax_include: booking_options.first.tax_include,
                        booking_at: Time.current,
                        details: {
                          new_customer_info: new_customer_info.attributes.compact,
                        },
                        sale_page_id: sale_page_id,
                        function_access_id: function_access_id
                      }],
                      menu_staffs_list: valid_menus_spots,
                      staff_states: staff_states,
                      memo: "",
                      with_warnings: false,
                      online: booking_options.all?(&:online?)
                    }
                  )

                  if reservation_outcome.valid?
                    reservation = reservation_outcome.result
                    throw :booked_reservation
                  else
                    errors.merge!(reservation_outcome.errors)
                  end
                end
              end
            end
          end

          if customer.persisted? && reservation
            # Track conversion if coming from function redirect
            if function_access_id.present?
              function_access = FunctionAccess.find_by(id: function_access_id)
              if function_access
                FunctionAccess.track_conversion(
                  content: function_access.content,
                  source_type: function_access.source_type,
                  source_id: function_access.source_id,
                  action_type: function_access.action_type,
                  revenue_cents: booking_options.sum(&:amount).cents,
                  label: function_access.label
                )
              end
            end

            compose(Users::UpdateCustomerLatestActivityAt, user: user)
            reservation_customer = reservation.reservation_customers.find_by!(customer: customer)

            Customers::RequestUpdate.run(reservation_customer: reservation_customer)

            if survey_answers.present?
              survey_outcome = Surveys::Reply.run(survey: booking_page.survey, owner: reservation_customer, answers: survey_answers)
            end

            booking_options.each do |booking_option|
              compose(Tickets::AutoProcess, customer: customer, product: booking_option, consumer: reservation_customer) if booking_option.ticket_enabled?
            end

            if stripe_token.present?
              compose(Customers::StorePaymentCustomer, customer: customer, authorize_token: stripe_token, payment_provider: user.stripe_provider)
              purchase_outcome = CustomerPayments::PayReservation.run(
                reservation_customer: reservation_customer,
                payment_provider: user.stripe_provider,
                payment_intent_id: payment_intent_id
              )

              if purchase_outcome.valid?
                reservation_customer.payment_paid!
              else
                errors.add(:base, :paying_reservation_something_wrong)
                errors.merge!(purchase_outcome.errors)
                raise ActiveRecord::Rollback
              end
            elsif square_token.present?
              compose(Customers::StorePaymentCustomer, customer: customer, authorize_token: square_token, payment_provider: user.square_provider)
              purchase_outcome = CustomerPayments::PayReservation.run(
                reservation_customer: reservation_customer,
                payment_provider: user.square_provider,
                source_id: square_token,
                location_id: square_location_id
              )

              if purchase_outcome.valid?
                reservation_customer.payment_paid!
              else
                errors.merge!(purchase_outcome.errors)
                errors.add(:base, :paying_reservation_something_wrong)
                raise ActiveRecord::Rollback
              end
            end

            ::RichMenus::BusinessSwitchRichMenu.run(owner: user)
            # send to customer
            ::ReservationBookingJob.perform_later(customer, reservation, email, phone_number, booking_page, booking_options.to_a)
            ::Notifiers::Users::PendingReservation.perform_later(receiver: user, reservation_customer: reservation_customer)

            # notify pending reservations summary immediately for today & tomorrow's reservation
            # Send to user
            if reservation.start_time < Time.current.tomorrow.end_of_day
              Notifiers::Users::PendingReservationsSummary.perform_later(
                start_time: Time.current.beginning_of_day,
                end_time: Time.current.tomorrow.end_of_day,
                receiver: user,
                user: user
              )
            end
          else
            Rollbar.error("Booking::CreateReservation Failed", errors: {
              customer_errors: customer&.errors&.details,
              reservation_errors: reservation&.errors&.details,
              errors: errors.details,
              reservation: reservation&.attributes,
              customer: customer&.attributes,
              booking_page_id: booking_page_id,
              booking_option_ids: booking_option_ids,
              booking_start_at: booking_start_at,
              user_id: user.id
            })

            errors.add(:base, :reservation_something_wrong)
            raise ActiveRecord::Rollback
          end

          {
            customer: customer,
            reservation: reservation
          }
        end
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
      @booking_page ||= BookingPage.find_by(slug: booking_page_id) || BookingPage.find(booking_page_id)
    end

    def booking_options
      @booking_options ||= user.booking_options.where(id: booking_option_ids)
    end

    def booking_end_at
      @booking_end_at ||= booking_start_at.advance(minutes: booking_options.sum(&:minutes))
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
          !customer_phone_number
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
      customer_info&.dig("phone_number").presence || customer_phone_number
    end

    def email
      customer_info&.dig("email").presence || customer_email
    end

    def social_customer
      SocialCustomer.find_by(social_user_id: social_user_id, user_id: booking_page.user_id) if social_user_id
    end

    def create_new_customer
      customer_outcome = Customers::Create.run(
        user: user,
        customer_last_name: customer_last_name,
        customer_first_name: customer_first_name,
        customer_phonetic_last_name: customer_phonetic_last_name,
        customer_phonetic_first_name: customer_phonetic_first_name,
        customer_phone_number: customer_phone_number,
        customer_email: customer_email,
        customer_reminder_permission: customer_reminder_permission
      )

      # XXX: Don't have to find a available reservation, since customer is invalid
      if customer_outcome.invalid?
        errors.merge!(customer_outcome.errors)

        raise ActiveRecord::Rollback
      end

      customer_outcome.result
    end

    def estimated_booking_amount
      booking_options.sum(&:amount)
    end

    def has_basic_customer_info?
      customer_last_name && customer_first_name && (customer_phone_number || customer_email)
    end
  end
end
