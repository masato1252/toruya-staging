require "rails_helper"

RSpec.describe BookingOptions::Update do
  let(:booking_option) { FactoryBot.create(:booking_option) }
  let(:user) { booking_option.user }
  let(:args) do
    {
      booking_option: booking_option,
      attrs: {
        name: "foo",
        display_name: "bar",
        minutes: 60,
        interval: 10,
        amount_cents: 1000,
        start_at: DateTime.now,
        end_at: nil
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates a booking option" do
      expect {
        outcome
      }.to change {
        user.booking_options.first.updated_at
      }
    end
  end
end
