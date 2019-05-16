require "rails_helper"

RSpec.describe Reservable::Staffs do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryBot.create(:shop) }
  let(:now) { Time.zone.now }
  let(:interval) { 10 }
  let(:menu_time) { 60 }
  let(:menu) { FactoryBot.create(:menu, :normal, user: user, shop: shop, minutes: menu_time, interval: interval) }
  let(:no_manpower_menu) { FactoryBot.create(:menu, :no_manpower, user: user, shop: shop) }
  let(:lecture_menu) { FactoryBot.create(:menu, :lecture_menu, user: user, shop: shop) }
  let(:staff) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
  let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
  let(:time_range) { now..now.advance(minutes: menu_time) }
  let(:customer1) { FactoryBot.create(:customer, user: user) }
  let(:customer2) { FactoryBot.create(:customer, user: user) }

  def create_available_menu(_menu)
    FactoryBot.create(:reservation_setting, day_type: "business_days", menu: _menu)
    FactoryBot.create(:staff_menu, menu: _menu, staff: staff)
  end

  describe "#run" do
    context "when staff is full time" do
      let!(:staff) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }

      before do
        FactoryBot.create(:staff_menu, menu: menu, staff: staff)
      end

      it "returns available staffs" do
        expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff.id)
      end

      context "when staffs don't have any reservations during that time" do
        context "when there are other no manpower menus exists" do
          before { create_available_menu(no_manpower_menu) }

          it "returns available staffs" do
            staff_options = Reservable::Staffs.run!(shop: shop, menu: no_manpower_menu, business_time_range: time_range, number_of_customer: 1)
            expect(staff_options.map(&:id)).to include(staff.id)
            expect(staff_options.map(&:handable_customers)).to include(no_manpower_menu.shop_menus.find_by(shop: shop).max_seat_number)
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 1).map(&:id)).to include(staff.id)
          end
        end
      end

      context "when all menu's staffs already had normal menu reservations during that time" do
        context "when old reservation is already full" do
          let!(:reservation) do
            FactoryBot.create(:reservation, shop: shop, menu: menu,
                               start_time: time_range.first, end_time: time_range.last,
                               staff_ids: [staff.id], customer_ids: [customer1.id, customer2.id])
          end

          context "when new reservation time doesn't overlap with old reservations" do
            let(:new_reservation_time_range) { now.advance(minutes: -(interval + menu_time))..now.advance(minutes: -interval) }

            it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: menu,
                                             business_time_range: new_reservation_time_range,
                                             number_of_customer: 1).map(&:id)).to include(staff.id)
            end
          end

          context "when new reservation time overlap with old reservations" do
            let(:new_reservation_time_range) { now.advance(minutes: -69)..now.advance(minutes: -9) }

            it "returns none" do
              expect(Reservable::Staffs.run!(shop: shop, menu: menu,
                                             business_time_range: new_reservation_time_range, number_of_customer: 1)).to eq(Staff.none)
            end
          end
        end

        let!(:reservation) do
          FactoryBot.create(:reservation, shop: shop, menu: menu,
                             start_time: time_range.first, end_time: time_range.last,
                             staff_ids: [staff.id], customer_ids: [customer1.id])
        end

        context "when new reservation time overlap with old reservations" do
          context "when old reservation is not full" do
            let(:new_reservation_time_range) { now.advance(minutes: -69)..now.advance(minutes: -9) }

            it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: menu,
                                             business_time_range: new_reservation_time_range,
                                             number_of_customer: 1).map(&:id)).to include(staff.id)
            end
          end
        end

        context "when staff is still affordable for the customer's quantity" do
          it "returns available staffs" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 1).map(&:id)).to include(staff.id)
          end

          context "when there are other no manpower menus exists" do
            before { create_available_menu(no_manpower_menu) }

            it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: no_manpower_menu, business_time_range: time_range, number_of_customer: 1).map(&:id)).to include(staff.id)
            end
          end
        end

        context "when staff isn't still affordable for too many customers" do
          it "returns none" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 2)).to eq(Staff.none)
          end

          context "menu do not have enough seat" do
            it "returns none" do
              expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 3)).to eq(Staff.none)
            end
          end

          context "when there are other no manpower menus exists" do
            before { create_available_menu(no_manpower_menu) }

            it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: no_manpower_menu, business_time_range: time_range, number_of_customer: 2).map(&:id)).to include(staff.id)
            end
          end
        end

        context "when there are other staffs could work on that menu during that time" do
          let(:staff2) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
          before { FactoryBot.create(:staff_menu, menu: menu, staff: staff2) }

          it "returns available staffs" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff.id)
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff2.id)
          end

          context "when the existing reservation's menu's need coperation(min_staffs_number > 1)" do
            let(:menu) { FactoryBot.create(:menu, :coperation, user: user, shop: shop) }
            let!(:reservation) do
              FactoryBot.create(:reservation, shop: shop, menu: menu,
                                 start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id, staff2.id])
            end

            context "when staff is still affordable for the customer's quantity" do
              it "returns available staffs" do
                staff_ids = Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 1).map(&:id)
                expect(staff_ids).to include(staff.id)
                expect(staff_ids).to include(staff2.id)
              end

              context "when there are other no reservation staffs could do this coperation menu" do
                let(:staff3) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
                let(:staff4) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
                before do
                  FactoryBot.create(:staff_menu, menu: menu, staff: staff3)
                  FactoryBot.create(:staff_menu, menu: menu, staff: staff4)
                end

                it "returns available staffs" do
                  staff_ids = Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range, number_of_customer: 1).map(&:id)

                  expect(staff_ids).to include(staff.id)
                  expect(staff_ids).to include(staff2.id)
                  expect(staff_ids).to include(staff3.id)
                  expect(staff_ids).to include(staff4.id)
                end
              end
            end
          end
        end

        context "when the existing reservation's menu does NOT need manpower" do
          let(:menu) { FactoryBot.create(:menu, user: user, min_staffs_number: 0, shop: shop) }

          it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff.id)
          end

          context "when there is other normal menus available" do
            let(:normal_menu) { FactoryBot.create(:menu, :normal, user: user, shop: shop) }
            before { create_available_menu(normal_menu) }

            it "returns available staffs" do
              expect(Reservable::Staffs.run!(shop: shop, menu: normal_menu, business_time_range: time_range).map(&:id)).to include(staff.id)
            end
          end
        end
      end

      context "when staff asks for leave on that date is during that time" do
        # business start time  -> custom_schedule start time -> business end_time
        context "when custom_schedule start time is between business start time and end time" do
          before do
            FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(minutes: 10), end_time: time_range.last)
          end

          it "returns empty" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range)).to be_empty
          end
        end

        # business start time  -> custom_schedule end time -> business end_time
        context "when custom_schedule end time time is between business start time and end time" do
          before do
            FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first, end_time: time_range.last.advance(minutes: -20))
          end

          it "returns empty" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range)).to be_empty
          end
        end

        # custom_schedule start time -> business start time  -> business end_time -> custom_schedule end time
        context "when custom_schedule time is ealier than business start time and custom_schedule end time is later than business end time" do
          before do
            FactoryBot.create(:custom_schedule, shop: shop,
                               staff: staff,
                               start_time: time_range.first.advance(minutes: -20),
                               end_time: time_range.last.advance(minutes: 20))
          end

          it "returns empty" do
            expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range)).to be_empty
          end
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        before do
          FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
        end

        it "returns available staffs" do
          expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff.id)
        end
      end
    end

    context "when staff has work schedule on that date" do
      let!(:staff) { FactoryBot.create(:staff, user: user, shop: shop) }
      let(:booking_time) do
        first_time = time_range.first
        last_time = time_range.last - menu.interval.to_i.minutes
        first_time..last_time
      end

      before do
        FactoryBot.create(:staff_menu, menu: menu, staff: staff)
        FactoryBot.create(:business_schedule, shop: shop, staff: staff, business_state: "opened", day_of_week: time_range.first.wday,
                           start_time: time_range.first, end_time: time_range.last)
      end

      it "returns available staffs" do
        expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: booking_time).map(&:id)).to include(staff.id)
      end

      context "when staff asks for leave on that date is at that time" do
        before do
          FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first, end_time: time_range.last)
        end

        it "returns empty" do
          expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: booking_time)).to be_empty
        end
      end

      context "when staff asks for leave on that date but not at that time" do
        before do
          FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: time_range.first.advance(hours: -2), end_time: time_range.last.advance(hours: -2))
        end

        it "returns available staffs" do
          expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: booking_time).map(&:id)).to include(staff.id)
        end
      end
    end

    context "when staff has open custom schedule on that date" do
      let!(:staff) { FactoryBot.create(:staff, user: user, shop: shop) }

      before do
        FactoryBot.create(:reservation_setting, menu: menu, day_type: "business_days")
        FactoryBot.create(:staff_menu, menu: menu, staff: staff)
        FactoryBot.create(:custom_schedule, :opened, staff: staff, shop: shop,
                           start_time: time_range.first, end_time: time_range.last + menu.interval.minutes)
      end

      it "returns available staffs" do
        expect(Reservable::Staffs.run!(shop: shop, menu: menu, business_time_range: time_range).map(&:id)).to include(staff.id)
      end
    end
  end
end
