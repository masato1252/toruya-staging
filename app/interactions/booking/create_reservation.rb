require "hash_deep_diff"

module Booking
  class CreateReservation < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :booking_page
    integer :booking_option_id
    time :booking_start_at
    string :customer_last_name, default: nil
    string :customer_first_name, default: nil
    string :customer_phonetic_last_name, default: nil
    string :customer_phonetic_first_name, default: nil
    string :customer_phone_number, default: nil
    string :customer_email, default: nil
    hash :customer_info, strip: false
    hash :present_customer_info, strip: false

    def execute
      reservation = nil
      if customer_info.present?
        # {"last_name"=> "chang", "phonetic_first_name"=> "lake", "phone_number"=> "88691081908", "address_details"=>{"postcode"=> "7107109"}}
        new_customer_info_hash = present_customer_info.changed_deep_diff(customer_info)

        customer = user.customers.find(customer_info["id"])
      else
        # new customer
        begin
          new_customer_info_hash = {
            last_name: customer_last_name,
            first_name: customer_first_name,
            phonetic_last_name: customer_phonetic_last_name,
            phonetic_first_name: customer_phonetic_first_name,
            emails: [{ type: "mobile", value: customer_email, primary: true }],
            email_types: "mobile",
            phone_numbers: [{ type: "mobile", value: customer_phone_number, primary: true }]
          }
          customer = user.customers.new(new_customer_info_hash)
          google_user = user.google_user
          result = google_user.create_contact(google_contact_attributes)
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
            if booking_option.menu_relations.order("priority").pluck(:menu_id) != same_time_reservation.reservation_menus.pluck(:menu_id)
              next
            end
          else
            if booking_option.menu_relations.order("priority").pluck(:menu_id).sort != same_time_reservation.reservation_menus.pluck(:menu_id).sort
              # check the same required time
              next
            end
          end

          menus_count = same_time_reservation.reservation_menus.count
          select_sql = <<-SELECT_SQL
              menu_id,
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
              business_time_range: reservation_staff_properties.work_start_at..reservation_staff_properties.work_end_at,
              menu_id: reservation_staff_properties.menu_id,
              booking_option_id: booking_option_id,
              staff_ids: reservation_staff_properties.staff_ids,
              reservation_id: same_time_reservation.id,
              number_of_customer: reservation.count_of_customers + 1,
              overlap_restriction: booking_page.overlap_restriction,
              skip_before_interval_time_validation: skip_before_interval_time_validation,
              skip_after_interval_time_validation: skip_after_interval_time_validation
            )

            if present_reservable_reservation_outcome.valid?
              same_time_reservation.customers << customer
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
            booking_page.overlap_restriction
          ) do |valid_menus_spots|
            # [
            #   {
            #     menu_id: menu_id,
            #     menu_interval_time: 10,
            #     staff_ids: $staff_ids,
            #     work_start_at: $work_start_time,
            #     work_end_at: $work_end_time
            #   }
            # ]
            # TODO: probably need record where the customer from in reservation_customers and probably move reservation's details to reservation_customers details
            reservation = compose(Reservations::Save,
              reservation: shop.reservations.new,
              params: {
                start_time: booking_start_at,
                end_time: booking_end_at,
                customers_list: [{
                  customer_id: customer.id,
                  booking_page_id: booking_page.id,
                  booking_option_id: booking_option_id,
                  amount_cents: booking_option.amount.fractional,
                  amount_currency: booking_option.amount.currency.to_s,
                  tax_include: booking_option.tax_excluded,
                  details: {
                    new_customer_info: new_customer_info_hash,
                    created_at: Time.current.to_s
                  }
                }],
                memo: "",
                with_warnings: false,
                menu_staffs_list: valid_menus_spots,
                booking_option_id: booking_option_id
              }
            )
            throw :booked_reservation
          end
        end
      end

      unless reservation
        errors.add(:base, "no_available_staffs")
      end
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
    rescue => e
      errors.add(:base, :something_wrong)
    end

    private

    def user
      @user ||= booking_page.user
    end

    def shop
      @shop ||= booking_page.shop
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
  end
end
