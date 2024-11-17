# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::UpdateAttribute do
  let(:shop) { FactoryBot.create(:shop) }
  let(:menu) { FactoryBot.create(:menu, user: shop.user, shop: shop, max_seat_number: 3, staffs: [FactoryBot.create(:staff, user: shop.user)]) }
  let(:menu_shops) {}
  let(:args) do
    {
      menu: menu,
      update_attribute: update_attribute,
      attrs: {
        menu_shops: menu_shops
      }
    }
  end
  let(:outcome) { described_class.run(args) }


  describe "#execute" do
    context "when update_attribute is minutes" do
      let(:update_attribute) { "minutes" }
      let(:minutes) { 200 }
      let(:args) do
        super().merge(attrs: { minutes: minutes })
      end

      it "updates menu minutes" do
        outcome

        expect(menu.reload.minutes).to eq(200)
      end

      context "when menu has a booking option" do
        let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, menus: [menu]) }

        it "updates booking option minutes" do
          expect {
            outcome
          }.to change {
            booking_option.reload.minutes
          }.to(200)
          expect(booking_option.booking_option_menus.first.required_time).to eq(200)
        end
      end
    end

    context "updates menu_shops" do
      let(:update_attribute) { "menu_shops" }
      let(:menu_shops) do
        [ { shop_id: shop.id, max_seat_number: 4, checked: true } ]
      end

      it "updates expected values" do
        outcome

        shop_menu = menu.shop_menus.first
        expect(shop_menu.max_seat_number).to eq(4)

        staff_menu = menu.staff_menus.first
        expect(staff_menu.max_customers).to eq(4)
      end

      context "when the shop be checked was used by a booking page" do
        let(:booking_page) { FactoryBot.create(:booking_page, shop: shop) }
        let!(:booking_option) { FactoryBot.create(:booking_option, booking_pages: [booking_page], menus: [menu]) }

        # menu need to be available for the booking page's shop
        # checked the menu's available shop(the same shop of booking page) is valid
        it "is valid" do
          expect(outcome).to be_valid
        end
      end

      context "when max_seat_number is nil" do
        let(:menu_shops) do
          [ { shop_id: shop.id, max_seat_number: nil, checked: true } ]
        end

        it "updates expected values, assume there is only one seat" do
          outcome

          shop_menu = menu.shop_menus.first
          expect(shop_menu.max_seat_number).to eq(1)

          staff_menu = menu.staff_menus.first
          expect(staff_menu.max_customers).to eq(1)
        end
      end

      context "when menu shops don't checked" do
        let(:menu_shops) do
          [ { shop_id: shop.id, max_seat_number: 4, checked: false } ]
        end

        it "updates expected values" do
          outcome

          expect(menu.shop_menus.exists?).to eq(false)
        end

        context "when the shop be unchecked was used by a booking page" do
          let(:booking_page) { FactoryBot.create(:booking_page, shop: shop) }
          let!(:booking_option) { FactoryBot.create(:booking_option, booking_pages: [booking_page], menus: [menu]) }

          # removing the menu's available shop(the same shop of booking page) is invalid
          # menu need to be available for the booking page's shop
          it "is invalid" do
            expect(outcome).to be_invalid
          end
        end
      end

      context "when menu require more than 1 staff" do
        let(:menu) { FactoryBot.create(:menu, shop: shop, max_seat_number: 3, staffs: [FactoryBot.create(:staff, user: shop.user)], min_staffs_number: 2) }

        it "updates expected values" do
          outcome

          shop_menu = menu.shop_menus.first
          expect(shop_menu.max_seat_number).to eq(4)

          staff_menu = menu.staff_menus.first
          expect(staff_menu.max_customers).not_to eq(4)
        end
      end
    end
  end
end
