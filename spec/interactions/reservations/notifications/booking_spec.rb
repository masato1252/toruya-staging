require "rails_helper"

RSpec.describe Reservations::Notifications::Booking do
  let(:subscription) { FactoryBot.create(:subscription, :premium) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:user) { subscription.user }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:reservation) { FactoryBot.create(:reservation, shop: FactoryBot.create(:shop, user: user)) }
  let(:message) { "foo" }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user, booking_pages: [booking_page]) }

  let(:args) do
    {
      phone_number: phone_number,
      customer: customer,
      reservation: reservation,
      message: message,
      booking_page: booking_page,
      booking_option: booking_option
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "calls Sms::Create" do
      expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))
      expect(Notifiers::Booking::ShopOwnerReservationBookedNotification).to receive(:perform_later).with(
        receiver: booking_page.shop.user,
        user: booking_page.shop.user,
        customer: customer,
        reservation: reservation,
        booking_page: booking_page,
        booking_option: booking_option
      )

      outcome
    end

    context "when subscription plan is not charge_required" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      it "don't calls Sms::Create" do
        expect(Sms::Create).not_to receive(:run)

        outcome
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
      before { FactoryBot.create(:social_customer, customer: customer, user: user) }

      it "calls Reservations::Notifications::SocialMessage" do
        expect(Reservations::Notifications::SocialMessage).to receive(:run!)

        outcome
      end
    end
  end
end
