# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::UpdateAttribute do
  let(:shop) { FactoryBot.create(:shop) }
  let(:menu) { FactoryBot.create(:menu, shop: shop, max_seat_number: 3, staffs: [FactoryBot.create(:staff, user: shop.user)]) }
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

      context "when menu shops don't checked" do
        let(:menu_shops) do
          [ { shop_id: shop.id, max_seat_number: 4, checked: false } ]
        end

        it "updates expected values" do
          outcome

          expect(menu.shop_menus.exists?).to eq(false)
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
