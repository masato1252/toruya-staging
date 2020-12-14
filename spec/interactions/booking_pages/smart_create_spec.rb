require "rails_helper"

RSpec.describe BookingPages::SmartCreate do
  let(:user) { FactoryBot.create(:user) }
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
    context "update_attribute is special_dates" do
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
    end
  end
end
