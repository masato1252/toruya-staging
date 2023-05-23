# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingPages::Save do
  let(:user) { FactoryBot.create(:user) }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:args) do
    {
      booking_page: booking_page,
      attrs: {
        shop_id: shop.id,
        name: "foo",
        title: "bar",
        interval: 10,
        start_at_date_part: DateTime.now.to_fs(:date),
        start_at_time_part: DateTime.now.to_fs(:time),
        end_at: nil,
        options: {
          "0" => { "label" => booking_option.name, "value" => booking_option.id }
        },
        special_dates: {
          "0" => {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59" }
        }
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when booking option is a new record" do
      let(:booking_page) { user.booking_pages.new }

      it "creates a booking page" do
        expect {
          outcome
        }.to change {
          user.booking_pages.reload.count
        }.by(1)

        expect(user.booking_pages.first.booking_options.first.id).to eq(booking_option.id)
      end
    end

    it "updates a booking page" do
      expect {
        outcome
      }.to change {
        user.booking_pages.first&.updated_at
      }
    end
  end
end
