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

    context "when testing social_account_skippable flag" do
      context "when user's customer_notification_channel is 'line'" do
        before do
          user.user_setting.update(customer_notification_channel: "line")
        end

        it "sets social_account_skippable to false" do
          expect(outcome.result.social_account_skippable).to eq(false)
        end
      end

      context "when user's customer_notification_channel is 'email'" do
        before do
          user.user_setting.update(customer_notification_channel: "email")
        end

        it "sets social_account_skippable to true" do
          expect(outcome.result.social_account_skippable).to eq(true)
        end
      end

      context "when user's customer_notification_channel is 'sms'" do
        before do
          user.user_setting.update(customer_notification_channel: "sms")
        end

        it "sets social_account_skippable to true" do
          expect(outcome.result.social_account_skippable).to eq(true)
        end
      end
    end

    context "when testing the BookingPages::ChangeLineSharing behavior" do
      it "calls BookingPages::ChangeLineSharing with the booking_page" do
        expect(BookingPages::ChangeLineSharing).to receive(:run).with(booking_page: booking_page)
        outcome
      end
    end

    context "when special_dates are provided" do
      it "creates the booking_page_special_dates" do
        expect { outcome }.to change { booking_page.booking_page_special_dates.count }.by(1)

        special_date = booking_page.booking_page_special_dates.first
        expect(special_date.start_at_date_part).to eq("2019-04-22")
        expect(special_date.start_at_time_part).to eq("01:00")
        expect(special_date.end_at_date_part).to eq("2019-04-22")
        expect(special_date.end_at_time_part).to eq("12:59")
      end
    end

    context "when booking_page update fails" do
      let(:error_mock) { instance_double("ActiveModel::Errors") }

      before do
        allow(booking_page).to receive(:update).and_return(false)
        allow(booking_page).to receive(:errors).and_return(error_mock)
        allow(error_mock).to receive(:messages).and_return({base: ["error"]})
        allow(error_mock).to receive(:full_messages).and_return(["Error message"])
        allow(error_mock).to receive(:details).and_return({base: [{error: "error"}]})
      end

      it "adds booking_page errors to the outcome errors" do
        outcome = described_class.run(args)
        expect(outcome).not_to be_valid
        expect(outcome.errors.full_messages).not_to be_empty
      end
    end
  end
end
