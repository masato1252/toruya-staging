# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingOptions::Prioritize do
  let(:user) { FactoryBot.create(:user) }
  let(:single_menu_booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user) }
  let(:single_coperation_menu_booking_option) { FactoryBot.create(:booking_option, :single_coperation_menu, user: user) }
  let(:multiple_menus_booking_option) { FactoryBot.create(:booking_option, :multiple_menus, user: user) }
  let(:multiple_coperation_menus_booking_option) { FactoryBot.create(:booking_option, :multiple_coperation_menus, user: user) }

  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:coperation_menu) { FactoryBot.create(:menu, :coperation, user: user) }

  let(:args) do
    {
      booking_options: [
        multiple_coperation_menus_booking_option,
        multiple_menus_booking_option,
        single_menu_booking_option,
        single_coperation_menu_booking_option
      ],
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "returns expected order" do
      expect(outcome.result).to eq([
        single_menu_booking_option,
        single_coperation_menu_booking_option,
        multiple_menus_booking_option,
        multiple_coperation_menus_booking_option,
      ])
    end
  end
end
