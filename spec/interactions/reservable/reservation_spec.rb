require "rails_helper"

RSpec.describe Reservable::Reservation do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryGirl.create(:shop) }
  let(:now) { Time.zone.now }
  let(:date) { now.to_date }
  let(:time_minutes) { 60 }
  let(:menu1) { FactoryGirl.create(:menu, shop: shop, minutes: time_minutes) }
  let(:menu2) { FactoryGirl.create(:menu, shop: shop, minutes: time_minutes) }
  let(:staff1) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop, menus: [menu1, menu2]) }
  let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop, menus: [menu1, menu2]) }
  let(:time_range) { now..now.advance(minutes: time_minutes * 2) }

  def create_available_menu(_menu)
    FactoryGirl.create(:staff_menu, menu: _menu, staff: staff)
  end

  describe "#execute" do
    context "when shop closed on that date" do
      it "is invalid" do
        outcome = Reservable::Reservation.run(shop: shop, date: date)

        expect(outcome).to be_invalid
        expect(outcome.errors.details[:date].first[:error]).to eq(:shop_closed)
      end
    end

    context "When shop open on that date" do
      before do
        FactoryGirl.create(:business_schedule, shop: shop,
                           start_time: now.beginning_of_day.advance(weeks: -1),
                           end_time: now.end_of_day.advance(weeks: -1))
      end

      context "when reservation time is short than menu working_time" do
        let(:time_range) { now..now.advance(minutes: time_minutes) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range)

          expect(outcome).to be_invalid
          expect(outcome.errors.details[:business_time_range].first[:error]).to eq(:too_short)
        end
      end

      context "when some menus doesn't have enough seats for customers" do
        let(:menu1) { FactoryGirl.create(:menu, shop: shop, minutes: time_minutes, max_seat_number: 4) }
        let(:menu2) { FactoryGirl.create(:menu, shop: shop, minutes: time_minutes, max_seat_number: 3) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range,
                                                number_of_customer: 4)

          expect(outcome).to be_invalid
          not_enough_seat_error = outcome.errors.details[:menu_ids].find { |error_hash| error_hash[:error] == :not_enough_seat }
          expect(not_enough_seat_error).to eq(error: :not_enough_seat, menu_name: menu2.name)
        end
      end

      context "when some staff doesn't have enough ability for customers" do
        let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop, menus: [menu1]) }
        before do
          FactoryGirl.create(:staff_menu, menu: menu2, staff: staff2, max_customers: 1)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id],
                                                number_of_customer: 2)

          expect(outcome).to be_invalid
          not_enough_ability_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :not_enough_ability }
          expect(not_enough_ability_error).to eq(error: :not_enough_ability, staff_name: staff2.name, menu_name: menu2.name)
        end
      end

      context "when reservation time is larger than menu working_time" do
        let(:time_range) { now..now.advance(minutes: time_minutes * 2) }

        it "is valid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range)

          expect(outcome).to be_valid
        end
      end

      context "when some staffs don't work on that date" do
        let(:staff2) { FactoryGirl.create(:staff, user: user, shop: shop) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id],
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          unworking_staff_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :unworking_staff }
          expect(unworking_staff_error).to eq(error: :unworking_staff, staff_name: staff2.name)
        end
      end

      context "when some staffs already had reservation in other shops" do
        before do
          FactoryGirl.create(:reservation, shop: FactoryGirl.create(:shop),
                             staffs: [staff2], start_time: time_range.first, end_time: time_range.last)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :other_shop }
          expect(other_shop_error).to eq(error: :other_shop, staff_name: staff2.name)
        end
      end

      context "when some staffs already had reservation in the same shop" do
        before do
          FactoryGirl.create(:reservation, shop: shop,
                             staffs: [staff2], start_time: time_range.first, end_time: time_range.last)
        end

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :overlap_reservations }
          expect(other_shop_error).to eq(error: :overlap_reservations, staff_name: staff2.name)
        end
      end

      context "when some staffs don't have ability for some menus" do
        let(:staff2) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop, menus: [menu1]) }

        it "is invalid" do
          outcome = Reservable::Reservation.run(shop: shop, date: date,
                                                menu_ids: [menu1.id, menu2.id],
                                                business_time_range: time_range,
                                                staff_ids: [staff1.id, staff2.id])

          expect(outcome).to be_invalid
          other_shop_error = outcome.errors.details[:staff_ids].find { |error_hash| error_hash[:error] == :incapacity_menu }
          expect(other_shop_error).to eq(error: :incapacity_menu, staff_name: staff2.name, menu_name: menu2.name)
        end
      end
    end
  end
end
