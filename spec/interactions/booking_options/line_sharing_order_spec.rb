# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingOptions::LineSharingOrder do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user) }
  let(:args) do
    {
      user: user,
      booking_option_ids: [booking_option.id]
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates rich_menu_only booking page" do
      expect {
        outcome
      }.to change {
        user.booking_pages.where(rich_menu_only: true).count
      }.by(1).and change {
        BookingPageOption.where(booking_option_id: booking_option.id).count
      }.by(1)
    end

    context "when there was already rich_menu_only booking_page exists" do
      before do
        booking_page = FactoryBot.create(:booking_page, :rich_menu_only, user: user)
        FactoryBot.create(:booking_page_option, booking_page: booking_page, booking_option: booking_option)
      end

      it "does NOT creates another rich_menu_only booking page" do
        expect {
          outcome
        }.not_to change {
          user.booking_pages.where(rich_menu_only: true).count
        }
      end
    end
  end
end
