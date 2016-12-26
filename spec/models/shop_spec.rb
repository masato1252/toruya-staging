require 'rails_helper'

RSpec.describe Shop, type: :model do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryGirl.create(:shop) }
  let(:now) { Time.zone.now }
  let(:menu) { FactoryGirl.create(:menu, :normal, user: user, minutes: 60, shop: shop) }
  let(:no_manpower_menu) { FactoryGirl.create(:menu, :no_manpower, user: user, shop: shop) }
  let(:lecture_menu) { FactoryGirl.create(:menu, :lecture_menu, user: user, shop: shop) }
  let(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
  let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
  let(:time_range) { now..now.advance(minutes: 60) }

  def create_available_menu(_menu)
    FactoryGirl.create(:reservation_setting, day_type: "business_days", menu: _menu)
    FactoryGirl.create(:staff_menu, menu: _menu, staff: staff)
  end

  describe "#available_time" do
    context "when shop has custom schedule" do
      let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, shop: shop,
                                                 start_time: now.beginning_of_day + 8.hours,
                                                 end_time: now.beginning_of_day + 16.hours) }

      context "when shop has business_schedule" do
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                     start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                     end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }

        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq(custom_schedule.end_time..business_schedule.end_time)
        end
      end

      context "when shop dose not have business_schedule" do
        it "returns nil" do
          expect(shop.available_time(now.to_date)).to be_nil
        end
      end
    end

    context "when that date is Japan holiday" do
      before { Timecop.freeze(Date.new(2016, 1, 1)) }

      context "when shop needs to work" do
        let(:shop) { FactoryGirl.create(:shop, holiday_working: true) }
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                      start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                      end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }


        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq(business_schedule.start_time..business_schedule.end_time)
        end
      end

      context "when shop does not need to work" do
        it "returns nil" do
          expect(shop.available_time(now.to_date)).to be_nil
        end
      end
    end
  end

  describe "#available_reservation_menus" do
    context "when staff is full time" do
      before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff) }

      context "when menus reservation is available on each business days" do
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, day_type: "business_days", menu: menu) }
        let(:staff_max_customers) { staff.staff_menus.where(menu: menu).first.max_customers }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when reservation time is shorter than menu required times" do
          let(:time_range) { now..now.advance(minutes: 59) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when menu is repeating rule" do
          before do
            menu.menu_reservation_setting_rule.update_attributes(reservation_type: "repeating", repeats: 2)
            FactoryGirl.create(:shop_menu_repeating_date, shop: shop, menu: menu)
          end

          it "returns available reservation menus" do
            expect(shop.available_reservation_menus(time_range)).to include(menu)
          end
        end

        context "when menu is due date rule" do
          before do
            menu.menu_reservation_setting_rule.update_attributes(reservation_type: "date", end_date: Time.zone.now.tomorrow.to_date)
            FactoryGirl.create(:shop_menu_repeating_date, shop: shop, menu: menu)
          end

          it "returns available reservation menus" do
            expect(shop.available_reservation_menus(time_range)).to include(menu)
          end
        end

        context "when reservation setting time is not available" do
          let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, menu: menu, day_type: "business_days", start_time: now.advance(months: -1, minute: 0), end_time: now.advance(months: -1, minutes: 59)) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6, shop: shop) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when staff had custom_schedule during that time" do
          let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, staff: staff, start_time: time_range.first, end_time: time_range.last) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when staff does NOT have reservations" do
          context "when menu min_staffs_number = 0" do
          end

          context "when menu min_staffs_number = 1" do
            context "when customers number is more than max staff max_customers" do
              it "returns empty" do

                expect(shop.available_reservation_menus(time_range, staff_max_customers + 1)).to be_empty
              end
            end

            context "when customers number is less or equal max staffs max_customers" do
              it "returns available reservation menus" do
                expect(shop.available_reservation_menus(time_range, staff_max_customers)).to include(menu)
              end
            end
          end

          context "when menu min_staffs_number > 1" do
            let(:menu) { FactoryGirl.create(:menu, :lecture, user: user, minutes: 60, shop: shop) }

            context "when staffs count is more than menus.min_staffs_number" do
              before do
                FactoryGirl.create(:staff_menu, menu: menu, staff: staff2)
              end

              context "when menu max_seat_number is more than customers number" do
                context "when staff's max_customers total is more than customers number" do
                  let(:customers_number) { menu.shop_menus.where(shop: shop).first.max_seat_number }
                  let(:total_staffs_customers) { shop.staffs.includes(:staff_menus).sum(:max_customers) }

                  it "returns available reservation menus" do
                    expect(total_staffs_customers).to be >= customers_number
                    expect(shop.available_reservation_menus(time_range, customers_number)).to include(menu)
                  end
                end

                context "when staff's max_customers total is less than customers number" do
                  let(:customers_number) do
                    4 + 1 # staff's max_customers total + 1
                  end
                  let!(:menu) { FactoryGirl.create(:menu, :lecture, user: user, minutes: 60, max_seat_number: customers_number + 1) }

                  it "returns empty" do
                    expect(shop.available_reservation_menus(time_range, customers_number)).to be_empty
                  end
                end
              end

              context "when menu max_seat_number is less than customers number" do
                it "returns empty" do
                  expect(shop.available_reservation_menus(time_range, menu.shop_menus.where(shop: shop).first.max_seat_number + 1)).to be_empty
                end
              end
            end

            context "when staffs count is less than menu.min_staffs_number" do
              it "returns empty" do
                expect(shop.available_reservation_menus(time_range)).to be_empty
              end
            end
          end
        end

        context "when staff already had reservations during that time" do
          context "when the exists reservation is different shop" do
            let!(:reservation) do
              FactoryGirl.create(:reservation, shop: FactoryGirl.create(:shop),
                                 menu: menu, staffs: [staff], start_time: time_range.first, end_time: time_range.last)
            end
            it "returns empty" do
              expect(shop.available_reservation_menus(time_range)).to be_empty
            end
          end

          context "when the existing reservation is the same shop" do
            let!(:reservation) { FactoryGirl.create(:reservation, shop: shop, menu: menu, staffs: [staff], start_time: time_range.first, end_time: time_range.last) }

            context "when there are other staffs could work on that menu during that time" do
              before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff2) }

              it "returns available reservation menus" do
                expect(shop.available_reservation_menus(time_range)).to include(menu)
              end
            end

            context "when passing reservation id" do
              it "returns available reservation menus ignore the passed reservation" do
                expect(shop.available_reservation_menus(time_range, 1, reservation.id)).to include(menu)
              end
            end

            context "when the existing reservation's menu min_staffs_number is 0" do
              let(:menu) { FactoryGirl.create(:menu, :no_manpower, user: user, shop: shop) }

              context "when menu max_seat_number is enough" do
                it "returns available reservation menus" do
                  expect(shop.available_reservation_menus(time_range)).to include(menu)
                end
              end

              context "when menu max_seat_number is not enough, some seats be occupied by other staff's reservation" do
                before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff2) }
                let!(:reservation2) { FactoryGirl.create(:reservation, shop: shop, menu: menu, staffs: [staff2], start_time: time_range.first, end_time: time_range.last) }
                it "returns available reservation menus" do
                  expect(shop.available_reservation_menus(time_range, 1)).to include(menu)
                end

                context "when ask too many customers" do
                  it "returns empty" do
                    expect(shop.available_reservation_menus(time_range, 2)).to be_empty
                  end
                end
              end
            end

            context "when existing reservation's menu min_staffs_number is 1" do
              let(:menu) { FactoryGirl.create(:menu, user: user, shop: shop) }

              context "when there is staff affordable" do
                it "returns available reservation menus" do
                  expect(shop.available_reservation_menus(time_range, 1)).to include(menu)
                end

                context "when menu max_seat_number is not enough, some seats be occupied by other staff's reservation" do
                  before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff2) }
                  let!(:reservation2) { FactoryGirl.create(:reservation, shop: shop, menu: menu, staffs: [staff2], start_time: time_range.first, end_time: time_range.last) }
                  it "returns available reservation menus" do
                    expect(shop.available_reservation_menus(time_range, 1)).to include(menu)
                  end

                  context "when ask too many customers" do
                    it "returns empty" do
                      expect(shop.available_reservation_menus(time_range, 2)).to be_empty
                    end
                  end
                end

                context "when no power menu is still available" do
                  before { create_available_menu(no_manpower_menu) }

                  it "returns available reservation menus" do
                    menus = shop.available_reservation_menus(time_range, 1)
                    expect(menus).to include(menu)
                    expect(menus).to include(no_manpower_menu)
                  end
                end
              end

              context "when there is no staff affordable" do
                it "returns available reservation menus" do
                  expect(shop.available_reservation_menus(time_range, 2)).to be_empty
                end
              end
            end

            context "when the existing reservations menu's needs cooperation(min_staffs_number > 1)" do
              let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
              let(:menu) { FactoryGirl.create(:menu, :cooperation, user: user, shop: shop, max_seat_number: 3) }
              # occupied by 1 customer
              let!(:reservation) do
                FactoryGirl.create(:reservation, shop: shop, menu: menu,
                                   start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id, staff2.id])
              end
              before do
                staff.staff_menus.where(menu: menu).first.update_columns(max_customers: 3)
                FactoryGirl.create(:staff_menu, menu: menu, staff: staff2, max_customers: 4)
              end

              context "when there are staffs affordable" do
                it "returns available reservation menus" do
                  expect(shop.available_reservation_menus(time_range, 2)).to include(menu)
                end

                context "when menu max_customers is enough, by one of staffs is not affordable" do
                  # staff is not affordable, staff2 is affordable
                  let(:menu) { FactoryGirl.create(:menu, :cooperation, user: user, shop: shop, max_seat_number: 4) }

                  it "returns empty" do
                    expect(shop.available_reservation_menus(time_range, 3)).to be_empty
                  end
                end

                context "when menu max_seat_number is not enough, some seats be occupied by other staff's reservation" do
                  let(:staff3) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
                  let(:staff4) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
                  before do
                    # occupied by another 1 customer
                    FactoryGirl.create(:reservation, shop: shop, menu: menu,
                                       start_time: time_range.first, end_time: time_range.last, staff_ids: [staff3.id, staff4.id])
                    FactoryGirl.create(:staff_menu, menu: menu, staff: staff3, max_customers: 4)
                    FactoryGirl.create(:staff_menu, menu: menu, staff: staff4, max_customers: 4)
                  end

                  it "returns empty" do
                    expect(shop.available_reservation_menus(time_range, 2)).to be_empty
                  end
                end
              end
            end
          end
        end

        context "when staff had reservations not during that time" do
          context "when reservation is in other shop" do
            before do
              shop_staff = FactoryGirl.create(:shop_staff, staff: staff)
              FactoryGirl.create(:reservation, shop: shop_staff.shop, menu: menu, staffs: [staff],
                                 start_time: time_range.first.advance(hours: -2),
                                 end_time: time_range.first.advance(hours: -1))
            end

            it "returns empty" do
              expect(shop.available_reservation_menus(time_range)).to be_empty
            end
          end

          context "when reservation is in the same shop" do
            before do
              FactoryGirl.create(:reservation, menu: menu, staffs: [staff], shop: shop,
                                 start_time: time_range.first.advance(hours: -2),
                                 end_time: time_range.first.advance(hours: -1))
            end

            it "returns available reservation menus" do
              expect(shop.available_reservation_menus(time_range)).to include(menu)
            end
          end
        end
      end

      context "when menus reservation is available on each Friday" do
        before { Timecop.freeze(Date.new(2016, 8, 5)) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, menu: menu, day_type: "weekly", days_of_week: [5]) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6, shop: shop) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end

      context "when menus reservation is available on second day of each Month" do
        before { Timecop.freeze(Date.new(2016, 8, 2)) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, :number_of_day_monthly, menu: menu, day_type: "monthly", day: 2) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6, shop: shop) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end

      context "when menus reservation is available on second Friday of each Month" do
        before { Timecop.freeze(Date.new(2016, 8, 12)) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, :day_of_week_monthly, menu: menu, day_type: "monthly", nth_of_week: 2, days_of_week: [5]) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6, shop: shop) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end
    end

    context "when staff is full time but staff asks for leave on that date but not at that time" do
      before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff) }
      context "when menus reservation is available on each business days" do
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, menu: menu, day_type: "business_days") }
        let(:staff_max_customers) { staff.staff_menus.where(menu: menu).first.max_customers }
        before do
          FactoryGirl.create(:custom_schedule, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
        end

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end
      end
    end

    context "when staff has work schedule on that date" do
      context "when menus reservation is available on each business days" do
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, menu: menu, day_type: "business_days") }
        let(:staff_max_customers) { staff.staff_menus.where(menu: menu).first.max_customers }
        before do
          FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
          FactoryGirl.create(:business_schedule, shop: shop, staff: staff, business_state: "opened",
                             day_of_week: time_range.first.advance(weeks: -1).wday,
                             start_time: time_range.first.advance(weeks: -1),
                             end_time: time_range.last.advance(weeks: -1))
        end

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        context "when menus reservation is available on each business days" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, shop: shop) }
          let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, menu: menu, day_type: "business_days") }
          let(:staff_max_customers) { staff.staff_menus.where(menu: menu).first.max_customers }
          before do
            FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
            FactoryGirl.create(:business_schedule, shop: shop, staff: staff, business_state: "opened", day_of_week: time_range.first.wday,
                               start_time: time_range.first, end_time: time_range.last)
            FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
          end

          it "returns available reservation menus" do
            expect(shop.available_reservation_menus(time_range)).to include(menu)
          end
        end
      end
    end
  end

  describe "#available_staffs" do
    context "when staff is full time" do
      let!(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }

      before do
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
      end

      it "returns available staffs" do
        expect(shop.available_staffs(menu, time_range)).to include(staff)
      end

      context "when all menu's staffs already had normal menu reservations at that time" do
        let!(:reservation) do
          FactoryGirl.create(:reservation, shop: shop, menu: menu,
                             start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id])
        end

        context "when staff is still affordable for the customer's quantity" do
          it "returns available staffs" do
            expect(shop.available_staffs(menu, time_range, 1)).to include(staff)
          end

          context "when there are other no manpower menus exists" do
            before { create_available_menu(no_manpower_menu) }

            it "returns available staffs" do
              expect(shop.available_staffs(no_manpower_menu, time_range, 1)).to include(staff)
            end
          end
        end

        context "when staff isn't still affordable for too many customers" do
          it "returns none" do
            expect(shop.available_staffs(menu, time_range, 2)).to eq(Staff.none)
          end

          context "when there are other no manpower menus exists" do
            before { create_available_menu(no_manpower_menu) }

            it "returns available staffs" do
              expect(shop.available_staffs(no_manpower_menu, time_range, 2)).to include(staff)
            end
          end
        end

        context "when there are other staffs could work on that menu during that time" do
          let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
          before { FactoryGirl.create(:staff_menu, menu: menu, staff: staff2) }

          it "returns available staffs" do
            expect(shop.available_staffs(menu, time_range)).to include(staff)
            expect(shop.available_staffs(menu, time_range)).to include(staff2)
          end

          context "when the existing reservation's menu's need cooperation(min_staffs_number > 1)" do
            let(:menu) { FactoryGirl.create(:menu, :cooperation, user: user, shop: shop) }
            let!(:reservation) do
              FactoryGirl.create(:reservation, shop: shop, menu: menu,
                                 start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id, staff2.id])
            end

            context "when staff is still affordable for the customer's quantity" do
              it "returns available staffs" do
                menus = shop.available_staffs(menu, time_range, 1)
                expect(menus).to include(staff)
                expect(menus).to include(staff2)
              end

              context "when there are other no reservation staffs could do this cooperation menu" do
                let(:staff3) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
                let(:staff4) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
                before do
                  FactoryGirl.create(:staff_menu, menu: menu, staff: staff3)
                  FactoryGirl.create(:staff_menu, menu: menu, staff: staff4)
                end

                it "returns available staffs" do
                  menus = shop.available_staffs(menu, time_range, 1)
                  expect(menus).to include(staff)
                  expect(menus).to include(staff2)
                  expect(menus).to include(staff3)
                  expect(menus).to include(staff4)
                end
              end
            end
          end
        end

        context "when the existing reservation's menu does NOT need manpower" do
          let(:menu) { FactoryGirl.create(:menu, user: user, min_staffs_number: 0, shop: shop) }

          it "returns available staffs" do
            expect(shop.available_staffs(menu, time_range)).to include(staff)
          end
        end
      end

      context "when staff asks for leave on that date is during that time" do
        # business start time  -> custom_schedule start time -> business end_time
        context "when custom_schedule start time is between business start time and end time" do
          before do
            FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(minutes: 10), end_time: time_range.last)
          end

          it "returns empty" do
            expect(shop.available_staffs(menu, time_range)).to be_empty
          end
        end

        # business start time  -> custom_schedule end time -> business end_time
        context "when custom_schedule end time time is between business start time and end time" do
          before do
            FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first, end_time: time_range.last.advance(minutes: -20))
          end

          it "returns empty" do
            expect(shop.available_staffs(menu, time_range)).to be_empty
          end
        end

        # custom_schedule start time -> business start time  -> business end_time -> custom_schedule end time
        context "when custom_schedule time is ealier than business start time and custom_schedule end time is later than business end time" do
          before do
            FactoryGirl.create(:custom_schedule, shop: shop,
                                                 staff: staff,
                                                 start_time: time_range.first.advance(minutes: -20),
                                                 end_time: time_range.last.advance(minutes: 20))
          end

          it "returns empty" do
            expect(shop.available_staffs(menu, time_range)).to be_empty
          end
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        before do
          FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
        end

        it "returns available staffs" do
          expect(shop.available_staffs(menu, time_range)).to include(staff)
        end
      end
    end

    context "when staff has work schedule on that date" do
      let!(:staff) { FactoryGirl.create(:staff, user: user, shop: shop) }
      let(:booking_time) do
        first_time = time_range.first
        last_time = time_range.last - menu.interval.to_i.minutes
        first_time..last_time
      end

      before do
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
        FactoryGirl.create(:business_schedule, shop: shop, staff: staff, business_state: "opened", day_of_week: time_range.first.wday,
                           start_time: time_range.first, end_time: time_range.last)
      end

      it "returns available staffs" do
        expect(shop.available_staffs(menu, booking_time)).to include(staff)
      end

      context "when staff asks for leave on that date is at that time" do
        before do
          FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first, end_time: time_range.last)
        end

        it "returns empty" do
          expect(shop.available_staffs(menu, booking_time)).to be_empty
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        before do
          FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
        end

        it "returns available staffs" do
          expect(shop.available_staffs(menu, booking_time)).to include(staff)
        end
      end
    end
  end

  # describe "#no_manpower_menus" do
  #   let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, shop: shop) }
  #   let(:no_manpower_menus) { FactoryGirl.create(:menu, :no_manpower, user: user, minutes: 60, shop: shop) }
  #   let(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
  #   before do
  #     FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
  #     FactoryGirl.create(:staff_menu, menu: no_manpower_menus, staff: staff)
  #   end
  #
  #   context "when even staff already reservation during that time" do
  #     before do
  #       FactoryGirl.create(:reservation, shop: shop, menu: menu,
  #                          start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id])
  #     end
  #
  #     it "still returns no_manpower menus" do
  #       expect(shop.available_reservation_menus(time_range)).to eq(Menu.none)
  #       expect(shop.no_manpower_menus(time_range)).to include(no_manpower_menus)
  #     end
  #   end
  #
  #   context "when staff had custom_schedule during that time" do
  #     let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, staff: staff, start_time: time_range.first, end_time: time_range.last) }
  #
  #     it "returns empty" do
  #       expect(shop.no_manpower_menus(time_range)).to eq(Menu.none)
  #     end
  #   end
  # end
end
