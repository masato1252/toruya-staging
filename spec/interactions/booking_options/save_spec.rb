# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingOptions::Save do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user) }
  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:args) do
    {
      booking_option: booking_option,
      attrs: {
        name: "foo",
        display_name: "bar",
        minutes: 60,
        amount_cents: 1000,
        start_at_date_part: DateTime.now.to_fs(:date),
        start_at_time_part: DateTime.now.to_fs(:time),
        menus: {
          "0" => { "label" => menu.name, "value" => menu.id, "priority" => 0 }
        }
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when booking option is a new record" do
      let(:booking_option) { user.booking_options.new }

      it "creates a booking option" do
        expect {
          outcome
        }.to change {
          user.booking_options.reload.count
        }.by(1)

        expect(user.booking_options.first.menus.first.id).to eq(menu.id)
      end
    end

    it "updates a booking option" do
      expect {
        outcome
      }.to change {
        user.booking_options.first&.menu_ids
      }
    end
  end
end
