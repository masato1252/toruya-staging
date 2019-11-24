require "rails_helper"

RSpec.describe BookingPages::AvailableBookingOptions do
  let(:shop) { FactoryBot.create(:shop) }
  let(:user) { shop.user }
  let(:args) do
    {
      shop: shop
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "returns the available booking options" do
      available_menu = FactoryBot.create(:menu, shop: shop)
      unavailable_menu = FactoryBot.create(:menu, shop: FactoryBot.create(:shop, user: user))

      availabe_booking_option = FactoryBot.create(:booking_option, user: user, menus: available_menu)
      unavailabe_booking_option = FactoryBot.create(:booking_option, user: user, menus: unavailable_menu)

      result = outcome.result

      expect(result.pluck(:id)).to include(availabe_booking_option.id)
      expect(result.pluck(:id)).not_to include(unavailabe_booking_option.id)
    end
  end
end
