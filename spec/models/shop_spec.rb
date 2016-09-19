require 'rails_helper'

RSpec.describe Shop, type: :model do
  let(:user) { shop.user }
  let(:shop) { FactoryGirl.create(:shop) }
  let(:now) { Time.zone.now }
  let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60) }
  let(:time_range) { now..now.advance(minutes: 60) }

  describe "#available_time" do
    context "when shop has custom schedule" do
      let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, shop: shop,
                                                 start_time: now.beginning_of_day + 8.hours,
                                                 end_time: now.beginning_of_day + 16.hours) }

      context "when shop has business_schedule" do
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                     start_time: now.beginning_of_day + 7.hours,
                                                     end_time: now.beginning_of_day + 18.hours) }

        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq((now.beginning_of_day + 16.hours)..(now.beginning_of_day + 18.hours))
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
                                                      start_time: now.beginning_of_day + 7.hours,
                                                      end_time: now.beginning_of_day + 18.hours) }


        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq((now.beginning_of_day + 7.hours)..(now.beginning_of_day + 18.hours))
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
    let(:params) {{ menu: menu }}

    context "when reservation time is shorter than menu required times" do
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days")) }
      let(:time_range) { now..now.advance(minutes: 59) }

      it "returns empty" do
        expect(shop.available_reservation_menus(time_range)).to be_empty
      end
    end

    context "when all staffs already had reservations at that time" do
      let(:staff) { FactoryGirl.create(:staff, user: user) }
      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
        FactoryGirl.create(:reservation, shop: shop, menu: menu,
                           start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id])
      end

      it "returns nil" do
        expect(shop.available_reservation_menus(time_range)).to be_nil
      end
    end

    shared_examples "available menus" do
      context "when menus reservation is available on each business days" do
        before { test_data if respond_to?(:test_data) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days")) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu min_staffs_number = 1" do
          context "when customers number is more than all staffs max_customers" do
            it "returns empty" do
              expect(shop.available_reservation_menus(time_range, 3)).to be_empty
            end
          end

          context "when customers number is less than all staffs max_customers" do
            it "returns available reservation menus" do
              expect(shop.available_reservation_menus(time_range, 2)).to include(menu)
            end
          end
        end

        context "when menu min_staffs_number > 1" do
          let(:menu) { FactoryGirl.create(:menu, :lecture, user: user, minutes: 60) }

          context "when staffs count is more than menus.min_staffs_number" do
            let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }

            before do
              FactoryGirl.create(:shop_staff, staff: staff2, shop: shop)
              FactoryGirl.create(:staff_menu, menu: menu, staff: staff2)
            end

            context "when menu max_seat_number is more than customers number" do
              it "returns available reservation menus" do
                expect(shop.available_reservation_menus(time_range, 3)).to include(menu)
              end
            end

            context "when menu max_seat_number is less than customers number" do
              it "returns empty" do
                expect(shop.available_reservation_menus(time_range, 4)).to be_empty
              end
            end
          end

          context "when staffs count is less than menu.min_staffs_number" do
            it "returns empty" do
              expect(shop.available_reservation_menus(time_range)).to be_empty
            end
          end
        end

        context "when reservation setting time is not available" do
          before { test_data if respond_to?(:test_data) }
          let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days", start_time: now.advance(minute: 0), end_time: now.advance(minutes: 59))) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6) }
          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end

        context "when staff already reservations during that time" do
          let!(:reservation) { FactoryGirl.create(:reservation, menu: menu, staffs: [staff], start_time: time_range.first, end_time: time_range.last) }

          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end

          context "when passing reservation id" do
            it "returns available reservation menus ignore the passed reservation" do
              expect(shop.available_reservation_menus(time_range, 1, reservation.id)).to include(menu)
            end
          end

          context "when the reservation's menu min_staffs_number is nil" do
            let(:menu) { FactoryGirl.create(:menu, :easy, user: user) }

            it "returns available reservation menus ignore min_staffs_number nil reservations" do
              expect(shop.available_reservation_menus(time_range)).to include(menu)
            end
          end
        end

        context "when staff had reservations not during that time" do
          before do
            FactoryGirl.create(:reservation, menu: menu, staffs: [staff],
                               start_time: time_range.first.advance(hours: -2),
                               end_time: time_range.first.advance(hours: -1))
          end

          it "returns available reservation menus" do
            expect(shop.available_reservation_menus(time_range)).to include(menu)
          end
        end

      end

      context "when menus reservation is available on each Friday" do
        before { Timecop.freeze(Date.new(2016, 8, 5)) }
        before { test_data if respond_to?(:test_data) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "weekly", days_of_week: [5])) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6) }
          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end

      context "when menus reservation is available on second day of each Month" do
        before { Timecop.freeze(Date.new(2016, 8, 2)) }
        before { test_data if respond_to?(:test_data) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, :number_of_day_monthly, params.merge(day_type: "monthly", day: 2)) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6) }
          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end

      context "when menus reservation is available on second Friday of each Month" do
        before { Timecop.freeze(Date.new(2016, 8, 12)) }
        before { test_data if respond_to?(:test_data) }
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, :day_of_week_monthly,
                                                        params.merge(day_type: "monthly", nth_of_week: 2, days_of_week: [5])) }

        it "returns available reservation menus" do
          expect(shop.available_reservation_menus(time_range)).to include(menu)
        end

        context "when menu does not have enough staffs" do
          let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60, min_staffs_number: 2, max_seat_number: 6) }
          it "returns empty" do
            expect(shop.available_reservation_menus(time_range)).to be_empty
          end
        end
      end
    end

    context "when staff is full time" do
      let(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }

      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:shop_menu, menu: menu, shop: shop)
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
      end

      it_behaves_like "available menus"

      context "when staff asks for leave on that date but not at that time" do
        it_behaves_like "available menus" do
          let(:test_data) do
            FactoryGirl.create(:custom_schedule, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
          end
        end
      end
    end

    context "when staff has work schedule on that date" do
      let(:staff) { FactoryGirl.create(:staff, user: user) }

      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:shop_menu, menu: menu, shop: shop)
      end

      it_behaves_like "available menus" do
        let(:test_data) do
          FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
          FactoryGirl.create(:business_schedule, shop: shop, staff: staff, business_state: "opened", day_of_week: time_range.first.wday,
                             start_time: time_range.first, end_time: time_range.last)
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        let(:menu) { FactoryGirl.create(:menu, user: user, minutes: 60) }

        it_behaves_like "available menus" do
          let(:test_data) do
            FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
            FactoryGirl.create(:business_schedule, shop: shop, staff: staff, business_state: "opened", day_of_week: time_range.first.wday,
                               start_time: time_range.first, end_time: time_range.last)
            FactoryGirl.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
          end
        end
      end
    end
  end

  describe "#available_staffs" do
    context "when all menu's staffs already had reservations at that time" do
      let(:staff) { FactoryGirl.create(:staff, user: user) }
      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:shop_menu, menu: menu, shop: shop)
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
        FactoryGirl.create(:reservation, shop: shop, menu: menu,
                                         start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id])
      end

      it "returns nil" do
        expect(shop.available_staffs(menu, time_range)).to be_nil
      end
    end

    context "when staff is full time" do
      let!(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }

      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
      end

      it "returns available staffs" do
        expect(shop.available_staffs(menu, time_range)).to include(staff)
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
      let!(:staff) { FactoryGirl.create(:staff, user: user) }
      let(:booking_time) do
        first_time = time_range.first
        last_time = time_range.last - menu.interval.to_i.minutes
        first_time..last_time
      end

      before do
        FactoryGirl.create(:shop_staff, staff: staff, shop: shop)
        FactoryGirl.create(:shop_menu, menu: menu, shop: shop)
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
end
