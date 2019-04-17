require "rails_helper"

RSpec.describe BookingOptions::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:args) do
    {
      user: user,
      attrs: {
        name: "foo",
        display_name: "bar",
        minutes: 60,
        interval: 10,
        amount_cents: 1000,
        start_at_date_part: DateTime.now.to_s(:date),
        start_at_time_part: DateTime.now.to_s(:time),
        end_at: nil,
        menu_ids: [menu.id]
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a booking option" do
      expect {
        outcome
      }.to change {
        user.booking_options.reload.count
      }.by(1)

      expect(user.booking_options.first.menus.first.id).to eq(menu.id)
    end
  end
end
