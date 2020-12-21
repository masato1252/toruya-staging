require "rails_helper"

RSpec.describe BookingPages::SmartCreate do
  let(:staff) { FactoryBot.create(:staff, :owner) }
  let(:user) { staff.staff_account.user }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:menu) { FactoryBot.create(:menu, shop: shop) }
  let(:args) do
    {
      attrs: {
        super_user_id: user.id,
        shop_id: shop.id,
        menu_id: menu.id,
        new_booking_option_price: 1000,
        new_booking_option_tax_include: true,
        note: "foo"
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when using existing booking option" do
      let!(:old_booking_option) { FactoryBot.create(:booking_option, user: user) }
      let(:args) do
        {
          attrs: {
            super_user_id: user.id,
            shop_id: shop.id,
            booking_option_id: old_booking_option.id,
            note: "foo"
          }
        }
      end

      it "creates expected booking_page and booking_option" do
        expect {
          outcome
        }.to change {
          user.booking_pages.count
        }.by(1).and change {
          user.booking_options.count
        }.by(0)

        booking_page = user.booking_pages.last
        booking_option = booking_page.booking_options.last
        booking_option_menu = booking_option.booking_option_menus.last

        expect(booking_page.name).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: old_booking_option.name))
        expect(booking_page.title).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: old_booking_option.name))
        expect(booking_page.greeting).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", menu_name: old_booking_option.name))
        expect(booking_page.shop_id).to eq(shop.id)
        expect(booking_page.note).to eq("foo")
        expect(booking_page.draft).to eq(false)

        expect(booking_option.id).to eq(old_booking_option.id)
      end
    end

    context "booking_option_id is nil" do
      context "when menu_id exists" do
        it "creates expected booking_page and booking_option" do
          expect {
            outcome
          }.to change {
            user.booking_pages.count
          }.by(1).and change {
            user.booking_options.count
          }.by(1)

          booking_page = user.booking_pages.last
          booking_option = booking_page.booking_options.last
          booking_option_menu = booking_option.booking_option_menus.last

          expect(booking_page.name).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu.short_name))
          expect(booking_page.title).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu.short_name))
          expect(booking_page.greeting).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", menu_name: menu.short_name))
          expect(booking_page.shop_id).to eq(shop.id)
          expect(booking_page.note).to eq("foo")
          expect(booking_page.draft).to eq(false)

          expect(booking_option.name).to eq(menu.name)
          expect(booking_option.display_name).to eq(menu.name)
          expect(booking_option.minutes).to eq(menu.minutes)
          expect(booking_option.amount_cents).to eq(1000)
          expect(booking_option.tax_include).to eq(true)

          expect(booking_option_menu.menu_id).to eq(menu.id)
          expect(booking_option_menu.required_time).to eq(menu.minutes)
        end
      end

      context "when menu_id is nil" do
        let(:new_menu_name) { "foo" }
        let(:args) do
          {
            attrs: {
              super_user_id: user.id,
              shop_id: shop.id,
              new_menu_name: new_menu_name,
              new_menu_minutes: 90,
              new_booking_option_price: 1000,
              new_booking_option_tax_include: true,
              note: "foo"
            }
          }
        end

        it "creates expected booking_page, booking_option and menu" do
          expect {
            outcome
          }.to change {
            user.booking_pages.count
          }.by(1).and change {
            user.booking_options.count
          }.by(1).and change {
            user.menus.count
          }.by(1).and change {
            user.categories.count
          }.by(1)

          booking_page = user.booking_pages.last
          booking_option = booking_page.booking_options.last
          booking_option_menu = booking_option.booking_option_menus.last
          menu = user.menus.last

          expect(booking_page.name).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: new_menu_name))
          expect(booking_page.title).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: new_menu_name))
          expect(booking_page.greeting).to eq(I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", menu_name: new_menu_name))
          expect(booking_page.shop_id).to eq(shop.id)
          expect(booking_page.note).to eq("foo")
          expect(booking_page.draft).to eq(false)

          expect(booking_option.name).to eq(menu.name)
          expect(booking_option.display_name).to eq(menu.name)
          expect(booking_option.minutes).to eq(menu.minutes)
          expect(booking_option.amount_cents).to eq(1000)
          expect(booking_option.tax_include).to eq(true)

          expect(booking_option_menu.menu_id).to eq(menu.id)
          expect(booking_option_menu.required_time).to eq(menu.minutes)

          expect(menu.name).to eq("foo")
          expect(menu.minutes).to eq(90)
          expect(menu.interval).to eq(0)
          expect(menu.min_staffs_number).to eq(1)
          expect(menu.category_ids).to eq(user.category_ids)
          expect(menu.shop_ids).to eq([shop.id])
          expect(menu.shop_menus.last.max_seat_number).to eq(1)
          expect(menu.staff_menus.last.max_customers).to eq(1)
          expect(menu.reservation_setting).to eq(user.reservation_settings.first)
          expect(menu.menu_reservation_setting_rule.start_date).to eq(Date.today)
          expect(menu.menu_reservation_setting_rule.end_date).to be_nil
          expect(menu.menu_reservation_setting_rule.reservation_type).to be_nil
        end
      end
    end
  end
end
