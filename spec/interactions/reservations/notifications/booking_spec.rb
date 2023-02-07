# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Notifications::Booking do
  let(:subscription) { FactoryBot.create(:subscription, :premium) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let!(:social_account) { FactoryBot.create(:social_account, user: user) }
  let(:user) { subscription.user }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:reservation) { FactoryBot.create(:reservation, shop: FactoryBot.create(:shop, user: user)) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user, booking_pages: [booking_page]) }

  let(:args) do
    {
      phone_number: phone_number,
      customer: customer,
      reservation: reservation,
      booking_page: booking_page,
      booking_option: booking_option
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "calls Sms::Create" do
      expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

      outcome
    end

    context "when subscription plan is not charge_required(free)" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      context 'when subscription is active' do
        it "calls Sms::Create" do
          expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

          outcome
        end
      end

      context 'when subscription is inactive' do
        let(:subscription) { FactoryBot.create(:subscription, :free_after_trial) }

        it "don't calls Sms::Create" do
          expect(Sms::Create).not_to receive(:run)

          outcome
        end
      end
    end

    context "when there is email argument" do
      before { args.merge!(email: Faker::Internet.email) }

      it "calls BookingMailer.customer_reservation_notification" do
        expect(BookingMailer).to receive(:with).and_return(double(customer_reservation_notification: double(deliver_later: true)))

        outcome
      end
    end

    context "when customer connected with social_customer" do
      let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer, user: user) }
      let!(:social_account) { FactoryBot.create(:social_account, user: user) }

      it "calls Reservations::Notifications::SocialMessage" do
        expected_message = Translator.perform(I18n.t("customer.notifications.sms.booking"), reservation.message_template_variables(customer))

        expect(Reservations::Notifications::SocialMessage).to receive(:run).with(
            { social_customer: social_customer, message: expected_message }
          ).and_return(double(invalid?: false, result: double))

        outcome
      end

      context "when there is shop custom message" do
        let(:scenario) { ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED }
        let!(:custom_message) { FactoryBot.create(:custom_message, service: booking_page.shop, scenario: scenario) }

        it "uses shop custom message template" do
          message = Translator.perform(custom_message.content, reservation.message_template_variables(customer))

          expect(Reservations::Notifications::SocialMessage).to receive(:run).with(
            { social_customer: social_customer, message: message }
          ).and_return(double(invalid?: false, result: double))

          outcome
        end
      end
    end
  end
end
