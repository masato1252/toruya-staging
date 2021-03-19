# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::ValidateSpecialDates do
  # Monday is work day
  let(:business_schedule) { FactoryBot.create(:business_schedule) }
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:booking_option_ids) { [FactoryBot.create(:booking_option, :single_menu, user: user).id] }
  let(:date) { "2019-05-13" }
  let(:start_at) { "09:00" }
  let(:end_at) { "17:00" }
  let(:special_dates) {[
    "{\"start_at_date_part\":\"#{date}\",\"start_at_time_part\":\"#{start_at}\",\"end_at_date_part\":\"#{date}\",\"end_at_time_part\":\"#{end_at}\"}"
  ]}
  let(:args) do
    {
      shop: shop,
      booking_option_ids: booking_option_ids,
      special_dates: special_dates
    }
  end
  let(:outcome) { described_class.run(args) }

  context "when special dates are working dates and doesn't beyond shop bussiness time" do
    it "is valid" do
      expect(outcome).to be_valid
    end
  end

  context "when special date is not working date" do
    let(:date) { "2019-05-06" }

    it "is invalid" do
      expect(outcome).to be_invalid
      expect(outcome.errors.details[:special_dates]).to include(error: :on_unworking_dates, invalid_dates: "2019年05月06日")
    end
  end

  context "when special date is working date" do
    context "start time is earlier than shop open time" do
      let(:start_at) { "08-59" }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:special_dates]).to include(error: :on_unworking_dates, invalid_dates: "2019年05月13日")
      end
    end

    context "end time is later than shop closed time" do
      let(:end_at) { "17:01" }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:special_dates]).to include(error: :on_unworking_dates, invalid_dates: "2019年05月13日")
      end
    end

    context "end time is later than start time" do
      let(:start_at) { "17:01" }
      let(:end_at) { "08-59" }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:special_dates]).to include(error: :on_unworking_dates, invalid_dates: "2019年05月13日")
      end
    end

    # booking option required time 60 and interval is 10 minutes
    RSpec.shared_examples "validate time length" do |start_at, end_at, required_time, valid|
      let(:start_at) { start_at }
      let(:end_at) { end_at }

      context "when start at is #{start_at}, end at is #{end_at} required_time is #{required_time} minutes" do
        it "is #{valid ? "valid" : "invalid"}" do
          expect(outcome.valid?).to eq(valid)

          unless valid
            expect(outcome.errors.details[:special_dates]).to include(error: :not_enough_time_dates, not_enough_time_dates: "2019/05/13 #{start_at} ~ #{end_at} #{required_time}")
          end
        end
      end
    end

    # the reservation starts at 9:00 AM, required time 60 (9:00 to 9:59) => Failed
    # the reservation starts at 9:00 AM, required time 60 (9:00 to 10:00) => OK
    # the reservation starts at 4:00 PM, required time 60 (16:00 to 17:00) => OK
    [
      {  start_at: "09:00", end_at: "09:59", required_time: 60, valid: false },
      {  start_at: "09:00", end_at: "10:00", required_time: 60, valid: true },
      {  start_at: "16:00", end_at: "17:00", required_time: 60, valid: true }
    ].each do |option|
      it_behaves_like "validate time length", option[:start_at], option[:end_at], option[:required_time], option[:valid]
    end
  end
end
