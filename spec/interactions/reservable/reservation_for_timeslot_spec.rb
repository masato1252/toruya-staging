# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservable::ReservationForTimeslot do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryBot.create(:shop, :holiday_working) }
  let(:now) { Time.zone.now }
  let(:date) { now.to_date }
  let(:time_minutes) { 60 }
  let(:menu1) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes) }
  let(:menu2) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes) }
  let(:staff1) { FactoryBot.create(:staff, :full_time, user: user, shop: shop, menus: [menu1, menu2]) }
  let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop, menus: [menu1, menu2]) }
  let(:total_require_time) { time_minutes * 2 }
  let(:time_range) { now..now.advance(minutes: total_require_time) }
  let(:start_time) { time_range.first }
  let(:end_time) { time_range.last }

  let(:args) {
    {
      shop: shop,
      date: date,
      start_time: start_time,
      total_require_time: total_require_time,
      interval_time: menu1.interval,
      staff_ids: [staff1.id],
      menu_ids: [menu1.id]
    }
  }

  let(:outcome) { Reservable::ReservationForTimeslot.run(args) }


  describe "#execute" do
    context "when shop closed on that date" do
      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end

    context "When shop open on that date" do
      before do
        FactoryBot.create(:business_schedule, shop: shop,
                           start_time: now.beginning_of_day.advance(weeks: -1),
                           end_time: now.end_of_day.advance(weeks: -1))
      end

      context "when reservation time is larger than menu working_time" do
        it "is valid" do
          expect(outcome).to be_valid
        end
      end

      # validate_booking_events
      context "when there other event booking pages had overlap times" do
        before { FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1) }
        let(:other_event_booking_page) { FactoryBot.create(:booking_page, event_booking: true, shop: shop) }
        let!(:other_booking_page_special_date) { FactoryBot.create(:booking_page_special_date, start_at: start_time, end_at: end_time, booking_page: other_event_booking_page) }
        let(:booking_page) { FactoryBot.create(:booking_page, event_booking: true, shop: shop) }

        it "is invalid" do
          args[:booking_page] = booking_page

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:booking_page]).to include(error: :overlap_event_booking, overlap_special_date_booking_page_ids: [other_event_booking_page.id])
        end

        context "when event_booking was in staff different shop" do
          let(:shop2) { FactoryBot.create(:shop) }
          let(:user2) { FactoryBot.create(:shop).user }
          let!(:staff1) { FactoryBot.create(:staff, :full_time, user: user, mapping_user: user, shop: shop, menus: [menu1, menu2]) }
          let!(:staff2) { FactoryBot.create(:staff, :full_time, user: user2, mapping_user: user2, shop: shop2) }
          let(:other_event_booking_page) { FactoryBot.create(:booking_page, event_booking: true, shop: shop2) }
          let!(:social_user) { FactoryBot.create(:social_user, user: user) }
          let!(:social_user2) { FactoryBot.create(:social_user, user: user2, social_service_user_id: social_user.social_service_user_id) }

          it "is invalid" do
            args[:booking_page] = booking_page

            expect(outcome).to be_invalid
            expect(outcome.errors.details[:booking_page]).to include(error: :overlap_event_booking, overlap_special_date_booking_page_ids: [other_event_booking_page.id])
          end
        end

        context 'when the booking was the event booking page had the same special dates' do
          let!(:booking_page_special_date) { FactoryBot.create(:booking_page_special_date, start_at: start_time, end_at: end_time, booking_page: booking_page) }

          it "is valid" do
            args[:booking_page] = other_event_booking_page

            expect(outcome).to be_valid
          end
        end
      end

      # validate_interval_time
      context "when there are reservations overlap in interval time" do
        context "when the overlap happened on previous reservation" do
          let!(:reservation) do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            FactoryBot.create(:reservation, shop: shop, menus: [ menu1 ],
                               start_time: time_range.first.advance(minutes: -menu1.minutes),
                               force_end_time: time_range.first,
                               staffs: staff1)
          end

          context "when the interval time is not enough for previous reservation" do
            it "is invalid" do
              expect(outcome).to be_invalid
              expect(outcome.errors.details[:start_time]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:end_time]).not_to include(error: :interval_too_short)
            end
          end

          context "when the interval time is enough for previous reservation but not enough for current reservation" do
            let(:menu2) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes, interval: 9) }
            let!(:reservation) do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu2)
              FactoryBot.create(:reservation, shop: shop, menus: [ menu2 ],
                                start_time: time_range.first.advance(minutes: -menu2.minutes),
                                force_end_time: time_range.first.advance(minutes: -menu2.interval),
                                staffs: [ staff1 ])
            end

            it "is invalid" do
              # XXX: The existing reservation need 9 minutes interval time(menu2),
              #      and the new booking reservation need 10 minutes interval time(menu1)
              #      but the interval time between two reservations is only 9 minutes
              expect(outcome).to be_invalid
              expect(outcome.errors.details[:start_time]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:end_time]).not_to include(error: :interval_too_short)
            end
          end

          context "when reservation is canceled" do
            before do
              reservation.cancel!
            end

            it "is valid" do
              expect(outcome).to be_valid
            end
          end
        end

        context "when the overlap happened on next reservation" do
          let!(:reservation) do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            FactoryBot.create(:reservation, shop: shop, menus: [ menu1 ],
                               start_time: time_range.last, end_time: time_range.last.advance(minutes: menu1.minutes),
                               staffs: staff1)
          end

          context "when the interval time is not enough for current reservation" do
            it "is invalid" do
              expect(outcome).to be_invalid
              expect(outcome.errors.details[:end_time]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:start_time]).not_to include(error: :interval_too_short)
            end
          end

          context "when the interval time is enough for current reservation, but not enough for next reservation" do
            let(:menu2) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes, interval: 20) }
            let!(:reservation) do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu2)
              FactoryBot.create(:reservation, shop: shop, menus: [ menu2 ],
                                start_time: time_range.last.advance(minutes: 19),
                                end_time: time_range.last.advance(minutes: 60),
                                staffs: staff1)
            end

            it "is invalid" do
              # XXX: The existing reservation need 20 minutes interval time(menu2),
              #      and the new booking reservation need 10 minutes interval time(menu1)
              #      but the interval time between two reservations is only 19 minutes
              expect(outcome).to be_invalid
              expect(outcome.errors.details[:end_time]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:start_time]).not_to include(error: :interval_too_short)
            end
          end

          context "when reservation is canceled" do
            before do
              reservation.cancel!
            end

            it "is valid" do
              expect(outcome).to be_valid
            end
          end
        end
      end

      # validate_menu_schedules
      # validate_seats_for_customers
      context "when some menus doesn't have enough seats for customers" do
        let(:menu1) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes, max_seat_number: 4) }

        it "is invalid" do
          args[:number_of_customer] = 5

          expect(outcome).to be_invalid
          not_enough_seat_error = outcome.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :not_enough_seat }
          expect(not_enough_seat_error).to eq(error: :not_enough_seat, menu_ids: [menu1.id])
        end

        context "when allow overbooking" do
          it "don't validate shop seat" do
            args[:overbooking_restriction] = false
            args[:number_of_customer] = 5

            not_enough_seat_error = outcome.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :not_enough_seat }
            expect(not_enough_seat_error).to be_nil
          end
        end
      end

      context "when some staffs don't work on that date" do
        context "when staff is a freelancer" do
          let(:staff2) { FactoryBot.create(:staff, user: user, shop: shop) }

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]
            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :freelancer }

            expect(unworking_staff_error).to eq(error: :freelancer, staff_id: staff2.id)
          end
        end

        context "when staff is a full time staff, ask for leave during(off schedule) the period" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before do
            schedule = FactoryBot.create(:custom_schedule, :closed, user: staff2.staff_account.user, start_time: time_range.first, end_time: time_range.last)
            FactoryBot.create(:social_user, user: schedule.user)
          end

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave, staff_id: staff2.id)
          end
        end

        context "when staff is a full time staff, had a personal schedule(off schedule) during the period" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before do
            schedule = FactoryBot.create(:custom_schedule, :closed, user: staff2.staff_account.user, start_time: time_range.first, end_time: time_range.last)
            FactoryBot.create(:social_user, user: schedule.user)
          end

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave, staff_id: staff2.id)
          end
        end

        context "when staff is a full time staff, had a personal schedule(off schedule) overlap menu interval" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before do
            schedule = FactoryBot.create(:custom_schedule, :closed, user: staff2.staff_account.user, start_time: time_range.first - 10.minute, end_time: time_range.first)
            FactoryBot.create(:social_user, user: schedule.user)
          end

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave, staff_id: staff2.id)
          end
        end

        context "when staff another account had a personal schedule(off schedule) during the period" do
          before do
            social_user = FactoryBot.create(:social_user, user: staff1.staff_account.user)
            social_user2 = FactoryBot.create(:social_user, social_service_user_id: social_user.social_service_user_id)
            user2 = social_user2.user
            FactoryBot.create(:custom_schedule, :closed, user: user2, start_time: time_range.first, end_time: time_range.last)
          end

          it "is invalid" do
            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave, staff_id: staff1.id)
          end
        end

        context "when staff is a part time staff, doesn't work on that day" do
          let(:staff2) { FactoryBot.create(:staff, user: user, shop: shop) }
          before do
            FactoryBot.create(:business_schedule, :opened, staff: staff2, shop: shop)
          end

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :unworking_staff }

            expect(unworking_staff_error).to eq(error: :unworking_staff, staff_id: staff2.id)
          end
        end
      end

      # validate_other_shop_reservation(staff)
      context "when some staffs already had reservation in other shops" do
        let!(:reservation) do
          FactoryBot.create(:reservation, shop: FactoryBot.create(:shop, user: user),
                            staffs: [staff2], start_time: start_time, end_time: end_time)
        end

        it "is invalid" do
          args[:staff_ids] = [staff1.id, staff2.id]

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :other_shop }
          expect(other_shop_error).to eq(error: :other_shop, staff_id: staff2.id)
        end

        # XXX: A staff's represent a user and this user might work for different owner
        #      So any existing reservation need to be checked whatever the owner
        context "when the existing reservation is not under current staff's user" do
          let!(:reservation) do
            other_owner_staff = FactoryBot.create(:staff_account, user: staff2.staff_account.user).staff
            FactoryBot.create(:social_user, user: staff2.staff_account.user)
            FactoryBot.create(:reservation, staffs: [other_owner_staff], start_time: time_range.first, end_time: time_range.last)
          end

          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_invalid
            other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :other_shop }
            expect(other_shop_error).to eq(error: :other_shop, staff_id: staff2.id)
          end
        end

        context "when reservation is canceled" do
          before do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation.cancel!
          end

          it "is valid" do
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_valid
          end
        end

        # XXX: If this new reservation is online, it doesn't matter where your existing reservation, only take of the time
        context "when it is is online reservation booking" do
          let(:menu1) { FactoryBot.create(:menu, :with_reservation_setting, shop: shop, minutes: time_minutes) }

          it "is valid" do
            args[:online_reservation] = true
            args[:start_time] = start_time.advance(hours: 2)
            args[:end_time] = end_time.advance(hours: 2)
            args[:staff_ids] = [staff1.id, staff2.id]

            expect(outcome).to be_valid
          end
        end
      end

      # validate_shop_capability_for_customers
      context "when shop/staff doesn't have capability to handle customers because of existing reservations" do
        context "when shop doesn't have capability(customers number > 3, staff's capability is 4)" do
          it "is invalid" do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, force_end_time: time_range.last, customers: FactoryBot.create(:customer, user: user))
            StaffMenu.find_by(staff_id: staff2.id, menu_id: menu1.id).update(max_customers: 4)

            args[:staff_ids] = [staff2.id]
            expect(outcome).to be_valid

            outcome2 = Reservable::ReservationForTimeslot.run(
              shop: shop,
              date: date,
              start_time: start_time,
              total_require_time: menu1.minutes,
              interval_time: menu1.interval,
              menu_ids: [menu1.id],
              staff_ids: [staff2.id],
              number_of_customer: 3
            )

            expect(outcome2).to be_invalid
            not_enough_ability_error = outcome2.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
            expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability, menu_id: menu1.id)
          end

          context "when there is new customer try too join existing reservation" do
            it "is invalid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, end_time: time_range.last,
                                              customers: FactoryBot.create(:customer, user: user))
              StaffMenu.find_by(staff_id: staff1.id, menu_id: menu1.id).update(max_customers: 4)

              args[:reservation_id] = reservation.id

              expect(outcome).to be_valid

              outcome2 = Reservable::ReservationForTimeslot.run(
                shop: shop,
                date: date,
                start_time: start_time,
                total_require_time: menu1.minutes,
                interval_time: menu1.interval,
                menu_ids: [menu1.id],
                reservation_id: reservation.id,
                staff_ids: [staff1.id],
                number_of_customer: 4
              )
              expect(outcome2).to be_invalid
              not_enough_ability_error = outcome2.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
              expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability, menu_id: menu1.id)
            end
          end

          context "when allow overbooking" do
            it "is valid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, end_time: time_range.last, customers: FactoryBot.create(:customer, user: user))
              StaffMenu.find_by(staff_id: staff1.id, menu_id: menu1.id).update(max_customers: 4)

              args[:reservation_id] = reservation.id
              args[:number_of_customer] = 4
              args[:overbooking_restriction] = false

              expect(outcome).to be_valid
            end
          end
        end

        context "when staff doesn't have capability(customers number > 2, shop's capability is 3)" do
          it "is invalid" do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, force_end_time: time_range.last, customers: FactoryBot.create(:customer, user: user))

            args[:staff_ids] = [staff2.id]

            expect(outcome).to be_valid

            outcome2 = Reservable::ReservationForTimeslot.run(
              shop: shop,
              date: date,
              start_time: start_time,
              total_require_time: menu1.minutes,
              interval_time: menu1.interval,
              menu_ids: [menu1.id],
              staff_ids: [staff2.id],
              number_of_customer: 2
            )
            expect(outcome2).to be_invalid
            not_enough_ability_error = outcome2.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
            expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability, menu_id: menu1.id)
          end

          context "when there is new customer try too join existing reservation" do
            it "is invalid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, end_time: time_range.last, customers: FactoryBot.create(:customer, user: user))

              args[:reservation_id] = reservation.id

              expect(outcome).to be_valid

              outcome2 = Reservable::ReservationForTimeslot.run(
                shop: shop,
                date: date,
                start_time: start_time,
                total_require_time: menu1.minutes,
                interval_time: menu1.interval,
                menu_ids: [menu1.id],
                reservation_id: reservation.id,
                staff_ids: [staff1.id],
                number_of_customer: 3
              )
              expect(outcome2).to be_invalid
              not_enough_ability_error = outcome2.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
              expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability, menu_id: menu1.id)
            end
          end

          context "when allow overbooking" do
            it "is valid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, force_end_time: time_range.last, customers: FactoryBot.create(:customer, user: user))

              args[:staff_ids] = [staff2.id]
              args[:number_of_customer] = 2
              args[:overbooking_restriction] = false

              expect(outcome).to be_valid
            end
          end
        end
      end

      # validate_same_shop_overlap_reservations(staff)
      context "when some staffs already had overlap reservation in the same shop" do
        let!(:reservation) do
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu2)
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
          FactoryBot.create(:reservation, menus: [ menu1 ], shop: shop, staffs: [staff2], start_time: time_range.first, force_end_time: time_range.last)
        end

        context "when booking the same menu" do
          it "is not overlap" do
            args[:staff_ids] = [staff2.id]

            expect(outcome).to be_invalid

            overlap_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :overlap_reservations }
            expect(overlap_error).to be_nil
          end
        end


        # existing reservation is menu1, booking menu2
        context "when booking a different menu" do
          it "is invalid" do
            args[:staff_ids] = [staff1.id, staff2.id]
            args[:menu_ids] = [menu2.id]
            args[:total_require_time] = menu2.minutes

            expect(outcome).to be_invalid
            overlap_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :overlap_reservations }
            expect(overlap_error).to eq(error: :overlap_reservations, staff_id: staff2.id)
          end
        end

        context "when the existing reservation's menu min_staffs_number is 0" do
          let(:menu1) { FactoryBot.create(:menu, :no_manpower, shop: shop, minutes: time_minutes) }

          it "is valid" do
            args[:staff_ids] = [staff2.id]
            args[:menu_ids] = [menu2.id]
            args[:total_require_time] = menu1.minutes

            expect(outcome).to be_valid
          end
        end

        context "when the reservation's menu try to book its min_staffs_number is 0(no man power menu)" do
          let(:menu2) { FactoryBot.create(:menu, :no_manpower, shop: shop, minutes: time_minutes) }

          it "is valid" do
            args[:staff_ids] = [staff2.id]
            args[:menu_ids] = [menu2.id]
            args[:total_require_time] = menu2.minutes
            args[:interval_time] = menu2.interval

            expect(outcome).to be_valid
          end
        end

        context "when the existing reservation is canceled" do
          before do
            reservation.cancel!
          end

          it "is valid" do
            args[:staff_ids] = [staff2.id]

            expect(outcome).to be_valid
          end
        end
      end

      # validate_staff_ability(staff)
      xcontext "when some staffs don't have ability for some menus" do
        let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop, menus: [menu2]) }

        it "is invalid" do
          # XXX: Staff2 only could handle menu2, has no ability to handle menu1
          args[:staff_ids] = [staff1.id, staff2.id]

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :incapacity_menu }
          expect(other_shop_error).to eq(error: :incapacity_menu, staff_id: staff2.id, menu_id: menu1.id)
        end
      end

      # validate_equipment_availability
      context "when equipment validation" do
        let(:equipment1) { FactoryBot.create(:equipment, shop: shop, quantity: 3) }
        let(:equipment2) { FactoryBot.create(:equipment, shop: shop, quantity: 2) }
        let!(:menu_equipment1) { FactoryBot.create(:menu_equipment, menu: menu1, equipment: equipment1, required_quantity: 2) }
        let!(:menu_equipment2) { FactoryBot.create(:menu_equipment, menu: menu1, equipment: equipment2, required_quantity: 1) }

        before do
          FactoryBot.create(:business_schedule, shop: shop,
                            start_time: now.beginning_of_day.advance(weeks: -1),
                            end_time: now.end_of_day.advance(weeks: -1))
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
        end

        context "when equipment is available" do
          it "is valid" do
            expect(outcome).to be_valid
          end
        end

        context "when equipment quantity is insufficient" do
          let!(:existing_reservation) do
            # Create a reservation that uses 2 units of equipment1, leaving only 1 available
            FactoryBot.create(:reservation,
                             shop: shop,
                             menus: [menu1],
                             start_time: start_time.advance(minutes: -30),
                             end_time: end_time.advance(minutes: -30),
                             staffs: [staff1])
          end

          it "is invalid when trying to reserve more equipment than available" do
            # The existing reservation uses 2 units of equipment1
            # The new reservation also needs 2 units of equipment1
            # But equipment1 only has 3 units total, so 2 + 2 = 4 > 3
            expect(outcome).to be_invalid
            insufficient_equipment_error = outcome.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :insufficient_equipment }
            expect(insufficient_equipment_error).to include(
              error: :insufficient_equipment,
              menu_id: menu1.id,
              equipment_name: equipment1.name,
              required: 2,
              available: 1
            )
          end
        end

        context "when multiple equipments have conflicts" do
          let!(:existing_reservation) do
            FactoryBot.create(:reservation,
                             shop: shop,
                             menus: [menu1],
                             start_time: start_time.advance(minutes: -30),
                             end_time: end_time.advance(minutes: -30),
                             staffs: [staff1])
          end

          before do
            # Make equipment2 also insufficient
            equipment2.update(quantity: 1)
          end

          it "shows all equipment conflicts" do
            expect(outcome).to be_invalid
            equipment_errors = outcome.errors.details[:menu_ids].select { |error_hash| error_hash[:error] == :insufficient_equipment }
            expect(equipment_errors.length).to eq(2)

            equipment1_error = equipment_errors.find { |error| error[:equipment_name] == equipment1.name }
            expect(equipment1_error).to include(
              error: :insufficient_equipment,
              equipment_name: equipment1.name,
              required: 2,
              available: 1
            )

            equipment2_error = equipment_errors.find { |error| error[:equipment_name] == equipment2.name }
            expect(equipment2_error).to include(
              error: :insufficient_equipment,
              equipment_name: equipment2.name,
              required: 1,
              available: 0
            )
          end
        end

        context "when updating existing reservation" do
          let!(:existing_reservation) do
            FactoryBot.create(:reservation,
                             shop: shop,
                             menus: [menu1],
                             start_time: start_time,
                             end_time: end_time,
                             staffs: [staff1])
          end

          it "excludes current reservation from equipment availability calculation" do
            args[:reservation_id] = existing_reservation.id

            # The existing reservation uses 2 units of equipment1
            # When updating the same reservation, it should not count against itself
            # So it should be valid even though it looks like it would exceed capacity
            expect(outcome).to be_valid
          end
        end

        context "when no overlap in time" do
          let!(:existing_reservation) do
            FactoryBot.create(:reservation,
                             shop: shop,
                             menus: [menu1],
                             start_time: start_time.advance(hours: -3),
                             end_time: start_time.advance(hours: -2),
                             staffs: [staff1])
          end

          it "is valid when reservations don't overlap in time" do
            expect(outcome).to be_valid
          end
        end

        context "when existing reservation is canceled" do
          let!(:existing_reservation) do
            FactoryBot.create(:reservation,
                             shop: shop,
                             menus: [menu1],
                             start_time: start_time.advance(minutes: -30),
                             end_time: end_time.advance(minutes: -30),
                             staffs: [staff1])
          end

          before do
            existing_reservation.cancel!
          end

          it "ignores canceled reservations for equipment availability" do
            expect(outcome).to be_valid
          end
        end

        context "when menu has no equipment requirements" do
          let(:menu_without_equipment) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes, max_seat_number: 4) }

          before do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu_without_equipment)
            args[:menu_ids] = [menu_without_equipment.id]
            args[:number_of_customer] = 1
            # 明確建立 staff_menu 關聯
            FactoryBot.create(:staff_menu, staff: staff1, menu: menu_without_equipment, max_customers: 4)
          end

          it "is valid when menu doesn't require any equipment" do
            expect(outcome).to be_valid
          end
        end

        context "when equipment is soft-deleted" do
          before do
            equipment1.update(deleted_at: Time.current)
          end

          it "ignores soft-deleted equipment in validation" do
            # equipment1 is soft-deleted, only equipment2 is checked (which is available)
            expect(outcome).to be_valid
          end
        end
      end
    end

    # validate_time_range
    context "when time range out of shop open/closed time" do
      before do
        FactoryBot.create(:business_schedule, shop: shop, start_time: Time.zone.local(2016, 12, 22, 9), end_time: Time.zone.local(2016, 12, 22, 17))
      end

      context "when start time is earlier than shop open time" do
        it "is invalid" do
          args[:start_time] = Time.zone.local(2016, 12, 22, 8, 59)
          args[:end_time] = Time.zone.local(2016, 12, 22, 12)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:start_time].first[:error]).to eq(:invalid_time)
        end
      end

      context "when end time is later than shop close time" do
        it "is invalid" do
          args[:start_time] = Time.zone.local(2016, 12, 22, 16, 59)
          args[:end_time] = Time.zone.local(2016, 12, 22, 17, 1)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:end_time].first[:error]).to eq(:invalid_time)
        end
      end

      context "when end time is earlier than start time" do
        it "is invalid" do
          args[:start_time] = Time.zone.local(2016, 12, 22, 17)
          args[:end_time] = Time.zone.local(2016, 12, 22, 16)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:end_time].first[:error]).to eq(:invalid_time)
        end
      end

      context "when start time is earlier than booking limit hours" do
        it "is invalid" do
          booking_page = FactoryBot.create(:booking_page, shop: shop, booking_limit_day: 0, booking_limit_hours: 1)
          args[:booking_page] = booking_page

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:start_time].first[:error]).to eq(:invalid_time)
        end
      end
    end
  end
end
