# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingPages::LineSharingOrder do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:args) do
    {
      user: user,
      booking_page_ids: [booking_page.id],
    }
  end
  let(:outcome) { described_class.run(args) }

  it "updates execpted data" do
    outcome

    expect(user.line_keyword_booking_page_ids).to include(booking_page.id.to_s)
    expect(booking_page.line_sharing).to eq(true)
  end
end
