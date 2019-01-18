require "rails_helper"

RSpec.describe Shops::Delete do
  let(:shop) { FactoryBot.create(:shop) }
  let(:user) { shop.user }
  let(:args) do
    {
      user: user,
      shop: shop,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updated deleted_at" do
      expect {
        outcome
      }.to change {
        shop.deleted_at
      }
    end

    context "when there are menus belongs to this shop" do
      let!(:menu1) { FactoryBot.create(:menu, user: user, shop: shop) }
      let!(:menu2) { FactoryBot.create(:menu, user: user, shop: shop) }

      context "when a menu only belongs to this shop" do
        it "delete the menu" do
          expect {
            outcome
          }.to change {
            shop.menus.count
          }.from(2).to(0)
        end
      end

      context "when a menu not only belongs to this shop" do
        before do
          FactoryBot.create(:shop_menu, menu: menu1, shop: FactoryBot.create(:shop, user: user), max_seat_number: 2)
        end

        it "delete the menu" do
          expect {
            outcome
          }.to change {
            shop.menus.count
          }.from(2).to(1)

          expect(shop.reload.menu_ids).to eq([menu1.id])
        end
      end
    end

    context "when there are reservation_settings belongs to this user" do
      let!(:menu) { FactoryBot.create(:menu, user: user, shop: shop) }
      let!(:reservation_settings1) { FactoryBot.create(:reservation_setting, user: user, menu: menu) }
      let!(:reservation_settings2) { FactoryBot.create(:reservation_setting, user: user, menu: menu) }

      context "when the deleted shop is user's final shop" do
        it "deletes all the reservation_settings" do
          expect {
            outcome
          }.to change {
            user.reservation_settings.count
          }.from(2).to(0)
        end
      end

      context "when the deleted shop is NOT user's final shop" do
        let!(:menu1) { FactoryBot.create(:menu, user: user, shop: shop) }
        let!(:reservation_settings1) { FactoryBot.create(:reservation_setting, user: user, menu: menu1) }
        let!(:menu2) { FactoryBot.create(:menu, user: user, shop: FactoryBot.create(:shop, user: user)) }
        let!(:reservation_settings2) { FactoryBot.create(:reservation_setting, user: user, menu: menu2) }

        it "do nothings" do
          expect {
            outcome
          }.to change {
            user.reservation_settings.count
          }.by(0)

          expect(user.shops.reload.count).to eq(1)
        end
      end
    end

    context "when there are menu categories belongs to this user" do
      let!(:category) { FactoryBot.create(:category, user: user) }

      context "when the deleted shop is user's final shop" do
        it "deletes the category" do
          expect {
            outcome
          }.to change {
            user.categories.count
          }.from(1).to(0)
        end
      end
    end

    context "when there are business_schedules belongs to this user's staff" do
      before do
        FactoryBot.create(:business_schedule, shop: shop, staff: FactoryBot.create(:staff, user: user))
      end

      context "when the deleted shop is user's final shop" do
        it "deletes the staff's business_schedule" do
          expect {
            outcome
          }.to change {
            BusinessSchedule.where(staff_id: user.staff_ids).count
          }.from(1).to(0)
        end
      end
    end

    context "when there are business_schedules belongs to this shop" do
      before do
        FactoryBot.create(:business_schedule, shop: shop)
      end

      it "deletes the shop's business_schedule" do
        expect {
          outcome
        }.to change {
          shop.business_schedules.count
        }.from(1).to(0)
      end
    end
  end
end
