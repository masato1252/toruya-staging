require "rails_helper"

RSpec.describe Reservable::Reservation do
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
  let(:time_range) { now..now.advance(minutes: time_minutes * 2) }
  let(:start_time) { time_range.first }
  let(:end_time) { time_range.last }


  describe "#execute" do
    context "when shop closed on that date" do
      it "is invalid" do
        outcome = Reservable::Reservation.run(shop: shop, date: date)

        expect(outcome).to be_invalid
      end
    end

    context "When shop open on that date" do
      before do
        FactoryBot.create(:business_schedule, shop: shop,
                           start_time: now.beginning_of_day.advance(weeks: -1),
                           end_time: now.end_of_day.advance(weeks: -1))
      end

      context "when reservation time is short than menu working_time" do
        let(:time_range) { now..now.advance(minutes: time_minutes) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu2.id,
                                                business_time_range: start_time..end_time.advance(minutes: -1))

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:menu_id]).to include(error: :time_not_enough)
        end
      end

      context "when reservation time is larger than menu working_time" do
        let(:time_range) { now..now.advance(minutes: time_minutes * 2) }

        before do
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
        end

        it "is valid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range)

          expect(outcome).to be_valid
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
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range)

              expect(outcome).to be_invalid
              expect(outcome.errors.details[:business_time_range]).to include(error: "previous_reservation_interval_overlap")
              expect(outcome.errors.details[:business_time_range]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:business_time_range]).not_to include(error: "next_reservation_interval_overlap")
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
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range)

              expect(outcome).to be_invalid
              expect(outcome.errors.details[:business_time_range]).to include(error: "previous_reservation_interval_overlap")
              expect(outcome.errors.details[:business_time_range]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:business_time_range]).not_to include(error: "next_reservation_interval_overlap")
            end
          end

          context "when reservation is canceled" do
            before do
              reservation.cancel!
            end

            it "is valid" do
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    staff_ids: [staff1.id])

              expect(outcome).to be_valid
            end
          end

          context "when allow to double booking" do
            it "is valid" do
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range,
                                                    overlap_restriction: false)

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
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range)

              expect(outcome).to be_invalid
              expect(outcome.errors.details[:business_time_range]).to include(error: "next_reservation_interval_overlap")
              expect(outcome.errors.details[:business_time_range]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:business_time_range]).not_to include(error: "previous_reservation_interval_overlap")
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
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range)

              expect(outcome).to be_invalid
              expect(outcome.errors.details[:business_time_range]).to include(error: "next_reservation_interval_overlap")
              expect(outcome.errors.details[:business_time_range]).to include(error: :interval_too_short)
              expect(outcome.errors.details[:business_time_range]).not_to include(error: "previous_reservation_interval_overlap")
            end
          end

          context "when reservation is canceled" do
            before do
              reservation.cancel!
            end

            it "is valid" do
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range)

              expect(outcome).to be_valid
            end
          end

          context "when allow to double booking" do
            it "is valid" do
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    staff_ids: [staff1.id],
                                                    business_time_range: time_range,
                                                    overlap_restriction: false)

              expect(outcome).to be_valid
            end
          end
        end
      end

      # validate_menu_schedules
      context "when menu doesn't allow to be booked on that date" do
        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:menu_id]).to include(error: :unschedule_menu)
        end
      end

      # validate_menu_schedules
      context "when menu doesn't start yet" do
        let!(:reservation_setting) { FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1) }
        before { MenuReservationSettingRule.where(menu: menu1).last.update_columns(start_date: Date.tomorrow) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:menu_id]).to include(error: :start_yet, start_at: Date.tomorrow.to_s)
        end
      end

      # validate_menu_schedules
      context "when menu was over" do
        let!(:reservation_setting) { FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1) }

        context "when rule had a particular end date" do
          before do
            menu1.menu_reservation_setting_rule.update_attributes(end_date: Date.yesterday)
          end

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range)

            expect(outcome).to be_invalid
            expect(outcome.errors.details[:menu_id]).to include(error: :is_over)
          end
        end

        context "when rule is repeating and over last date" do
          let(:now) { Time.zone.now.tomorrow.tomorrow }
          before do
            menu1.menu_reservation_setting_rule.update_attributes(reservation_type: "repeating", repeats: 2)
            FactoryBot.create(:shop_menu_repeating_date, shop: shop, menu: menu1)
          end

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range)

            expect(outcome).to be_invalid
            expect(outcome.errors.details[:menu_id]).to include(error: :is_over)
          end
        end
      end

      # validate_seats_for_customers
      context "when some menus doesn't have enough seats for customers" do
        let(:menu1) { FactoryBot.create(:menu, shop: shop, minutes: time_minutes, max_seat_number: 4) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range,
                                                number_of_customer: 5)

          expect(outcome).to be_invalid
          not_enough_seat_error = outcome.errors.details[:menu_id].find { |error_hash| error_hash[:error] == :not_enough_seat }
          expect(not_enough_seat_error).to eq(error: :not_enough_seat)
        end
      end

      # validate_staffs_ability_for_customers(staff)
      context "when some staff doesn't have enough ability for customers" do
        let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
        before do
          FactoryBot.create(:staff_menu, menu: menu1, staff: staff2, max_customers: 1)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id],
                                                number_of_customer: 2)

          expect(outcome).to be_invalid
          not_enough_ability_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :not_enough_ability }
          expect(not_enough_ability_error).to eq(error: :not_enough_ability)
        end
      end

      context "when some staffs don't work on that date" do
        context "when staff is a freelancer" do
          let(:staff2) { FactoryBot.create(:staff, user: user, shop: shop) }

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :freelancer }

            expect(unworking_staff_error).to eq(error: :freelancer)
            expect(outcome.errors.details[:freelancer]).to include(error: staff2.id.to_s)
          end
        end

        context "when staff is a full time staff, ask for leave during(off schedule) the period" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before do
            FactoryBot.create(:custom_schedule, :closed, staff: staff2, start_time: time_range.first, end_time: time_range.last)
          end

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave)
            expect(outcome.errors.details[:ask_for_leave]).to include(error: staff2.id.to_s)
          end
        end

        context "when staff is a full time staff, had a personal schedule(off schedule) during the period" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before do
            FactoryBot.create(:custom_schedule, :closed, user: staff2.staff_account.user, start_time: time_range.first, end_time: time_range.last)
          end

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :ask_for_leave }

            expect(unworking_staff_error).to eq(error: :ask_for_leave)
            expect(outcome.errors.details[:ask_for_leave]).to include(error: staff2.id.to_s)
            expect(outcome.errors.details[:ask_for_leave]).not_to include(error: staff1.id.to_s)
          end
        end

        context "when staff is a part time staff, doesn't work on that day" do
          let(:staff2) { FactoryBot.create(:staff, user: user, shop: shop) }
          before do
            FactoryBot.create(:business_schedule, :opened, staff: staff2, shop: shop)
          end

          it "is invalid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_invalid
            unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :unworking_staff }

            expect(unworking_staff_error).to eq(error: :unworking_staff)
            expect(outcome.errors.details[:unworking_staff]).to include(error: staff2.id.to_s)
          end
        end
      end

      # validate_other_shop_reservation(staff)
      context "when some staffs already had reservation in other shops" do
        let!(:reservation) do
          FactoryBot.create(:reservation, shop: FactoryBot.create(:shop),
                             staffs: [staff2], start_time: time_range.first, end_time: time_range.last)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :other_shop }
          expect(other_shop_error).to eq(error: :other_shop)
        end

        context "when reservation is canceled" do
          before do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation.cancel!
          end

          it "is valid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_valid
          end
        end
      end

      # validate_shop_capability_for_customers
      context "when shop/staff doesn't have capability to handle customers because of existing reservations" do
        context "when shop doesn't have capability(customers number > 3, staff's capability is 4)" do
          it "is invalid" do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, force_end_time: time_range.last,
                                            customers: FactoryBot.create(:customer, user: user))
            StaffMenu.find_by(staff_id: staff2.id, menu_id: menu1.id).update(max_customers: 4)

            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id])

            expect(outcome).to be_valid

            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id],
                                                  number_of_customer: 3)
            expect(outcome).to be_invalid
            not_enough_ability_error = outcome.errors.details[:menu_id].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
            expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability)
          end

          context "when there is new customer try too join existing reservation" do
            it "is invalid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, end_time: time_range.last,
                                              customers: FactoryBot.create(:customer, user: user))
              StaffMenu.find_by(staff_id: staff1.id, menu_id: menu1.id).update(max_customers: 4)

              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    reservation_id: reservation.id,
                                                    staff_ids: [staff1.id])

              expect(outcome).to be_valid

              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    reservation_id: reservation.id,
                                                    staff_ids: [staff1.id],
                                                    number_of_customer: 4)
              expect(outcome).to be_invalid
              not_enough_ability_error = outcome.errors.details[:menu_id].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
              expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability)
            end
          end
        end

        context "when staff doesn't have capability(customers number > 2, shop's capability is 3)" do
          it "is invalid" do
            FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
            reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, force_end_time: time_range.last,
                                            customers: FactoryBot.create(:customer, user: user))

            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id])

            expect(outcome).to be_valid

            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id],
                                                  number_of_customer: 2)
            expect(outcome).to be_invalid
            not_enough_ability_error = outcome.errors.details[:menu_id].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
            expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability)
          end

          context "when there is new customer try too join existing reservation" do
            it "is invalid" do
              FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
              reservation = FactoryBot.create(:reservation, menus: [menu1], shop: shop, staffs: [staff1], start_time: time_range.first, end_time: time_range.last,
                                              customers: FactoryBot.create(:customer, user: user))

              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    reservation_id: reservation.id,
                                                    staff_ids: [staff1.id])

              expect(outcome).to be_valid

              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    reservation_id: reservation.id,
                                                    staff_ids: [staff1.id],
                                                    number_of_customer: 3)
              expect(outcome).to be_invalid
              not_enough_ability_error = outcome.errors.details[:menu_id].find { |error_hash| error_hash[:error] == :shop_or_staff_not_enough_ability }
              expect(not_enough_ability_error).to eq(error: :shop_or_staff_not_enough_ability)
            end
          end
        end
      end

      # validate_same_shop_overlap_reservations(staff)
      context "when some staffs already had overlap reservation in the same shop" do
        let!(:reservation) do
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
          FactoryBot.create(:reservation, menus: [ menu1 ], shop: shop, staffs: [staff2], start_time: time_range.first, force_end_time: time_range.last)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :overlap_reservations }
          expect(other_shop_error).to eq(error: :overlap_reservations)
        end

        context "when the existing reservation's menu min_staffs_number is 0" do
          let(:menu1) { FactoryBot.create(:menu, :no_manpower, shop: shop, minutes: time_minutes) }

          it "is valid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id])

            expect(outcome).to be_valid
          end
        end

        context "when the existing reservation is canceled" do
          before do
            reservation.cancel!
          end

          it "is valid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id])

            expect(outcome).to be_valid
          end
        end

        context "when allow to double booking" do
          it "is valid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff2.id],
                                                  overlap_restriction: false)

            expect(outcome).to be_valid
          end
        end
      end

      # validate_staff_ability(staff)
      context "when some staffs don't have ability for some menus" do
        let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop, menus: [menu2]) }

        it "is invalid" do
          # XXX: Staff2 only could handle menu2, has no ability to handle menu1
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_id: menu1.id,
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])


          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :incapacity_menu }
          expect(other_shop_error).to eq(error: :incapacity_menu)
        end
      end

      # validate_lack_overlap_staff(staff, index)
      context "when multiple staff required menu lack staff or had overlap staffs" do
        before do
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1)
          FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu2)
        end

        context "selected staffs number are equal menus required" do
          it "is valid" do
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id, staff2.id])

            expect(outcome).to be_valid
          end

          context "selected staffs are overlap" do
            let(:menu1) { FactoryBot.create(:menu, :lecture, shop: shop, minutes: time_minutes) }

            it "is invalid" do
              outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                    menu_id: menu1.id,
                                                    business_time_range: time_range,
                                                    staff_ids: [staff1.id, staff1.id])

              expect(outcome).to be_invalid
              other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :lack_overlap_staffs }
              expect(other_shop_error).to eq(error: :lack_overlap_staffs)
            end
          end
        end

        context "selected staffs number are less than menus required" do
          let(:menu1) { FactoryBot.create(:menu, :lecture, shop: shop, minutes: time_minutes) }

          it "is invalid" do
            # menus required 2 staffs but we only assign one
            outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                  menu_id: menu1.id,
                                                  business_time_range: time_range,
                                                  staff_ids: [staff1.id])

            expect(outcome).to be_invalid
            other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :lack_overlap_staffs }
            expect(other_shop_error).to eq(error: :lack_overlap_staffs)
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
          outcome = Reservable::Reservation.run(
            shop: shop, date: date,
            menu_id: menu1.id,
            business_time_range: Time.zone.local(2016, 12, 22, 8, 59)..Time.zone.local(2016, 12, 22, 12)
          )

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:business_time_range].first[:error]).to eq(:invalid_time_range)
        end
      end

      context "when end time is later than shop open time" do
        it "is invalid" do
          outcome = Reservable::Reservation.run(
            shop: shop, date: date,
            menu_id: menu1.id,
            business_time_range: Time.zone.local(2016, 12, 22, 16, 59)..Time.zone.local(2016, 12, 22, 17, 1)
          )

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:business_time_range].first[:error]).to eq(:invalid_time_range)
        end
      end

      context "when end time is earlier than start time" do
        it "is invalid" do
          outcome = Reservable::Reservation.run(
            shop: shop, date: date,
            menu_id: menu1.id,
            business_time_range: Time.zone.local(2016, 12, 22, 17)..Time.zone.local(2016, 12, 22, 16)
          )

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:business_time_range].first[:error]).to eq(:invalid_time_range)
        end
      end
    end
  end
end
