# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Customers::Update do
  let(:content) { "foo" }
  let(:after_days) { nil }
  let(:before_minutes) { nil }
  let(:args) do
    {
      message: custom_message,
      content: content,
      after_days: after_days,
      before_minutes: before_minutes,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context 'when service is OnlineService' do
      let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
      let(:custom_message) { FactoryBot.create(:custom_message, service: service, after_days: nil) }
      let(:service) { relation.online_service }
      let(:content) { "bar" }
      let(:after_days) { 3 }

      it "updates a custom_message" do
        outcome

        expect(custom_message.content).to eq(content)
        expect(custom_message.after_days).to eq(after_days)
      end

      context "when new message's after_days is not nil or 0" do
        let(:after_days) { 1 }

        it "schedules to send all the available customers" do
          allow(CustomMessages::Customers::Next).to receive(:perform_later)

          result = outcome.result

          expect(CustomMessages::Customers::Next).to have_received(:perform_later).with({
            custom_message: result,
            receiver: relation.customer,
            schedule_right_away: true
          })
        end
      end
    end

    context 'when service is BookingPage' do
      let(:service) { FactoryBot.create(:booking_page) }
      let(:scenario) { CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER }
      let(:custom_message) { FactoryBot.create(:custom_message, scenario: scenario, service: service, before_minutes: 10) }
      let(:content) { "bar" }
      let(:before_minutes) { 15 }

      it "updates a custom_message" do
        outcome

        expect(custom_message.content).to eq(content)
        expect(custom_message.before_minutes).to eq(before_minutes)
      end

      context "when after_days is set" do
        let(:scenario) { CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER}
        let(:custom_message) { FactoryBot.create(:custom_message, scenario: scenario, service: service, after_days: after_days, content: content) }
        let(:before_minutes) { nil }
        let(:after_days) { 3 }

        it "updates a custom_message" do
          outcome

          expect(custom_message.content).to eq(content)
          expect(custom_message.after_days).to eq(after_days)
        end
      end

      context "when there are existing future reservations" do
        let!(:reservation_customer) { FactoryBot.create(:reservation_customer, booking_page: service) }
        let(:reservation) { reservation_customer.reservation }
        let(:customer) { reservation_customer.customer }
        before do
          # Make reservation and customer able to remind
          reservation.accept!
          reservation_customer.accepted!
          customer.update(reminder_permission: true)
        end

        context 'when before_minutes changed' do
          it 'schedules reminder for future reservations' do
            expect(Notifiers::Customers::CustomMessages::ReservationReminder).to receive(:perform_at) do |args|
              expect(args[:schedule_at].round).to eq(reservation.start_time.advance(minutes: -before_minutes).round)
            end

            outcome
          end
        end

        context 'when after_days changed' do
          let(:scenario) { CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER }
          let(:custom_message) { FactoryBot.create(:custom_message, scenario: scenario, service: service, after_days: 1) }
          let(:before_minutes) { nil }
          let(:after_days) { 2 }

          it 'schedules reminder for future reservations' do
            expect(Notifiers::Customers::CustomMessages::ReservationReminder).to receive(:perform_at) do |args|
              expect(args[:schedule_at].round).to eq(reservation.start_time.advance(days: after_days).round)
            end

            outcome
          end
        end

        context "when after_days doesn't change" do
          let(:scenario) { CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER }
          let(:custom_message) { FactoryBot.create(:custom_message, scenario: scenario, service: service, after_days: 2) }
          let(:after_days) { 2 }

          it "doesn't schedule reminder for future reservations" do
            expect(Notifiers::Customers::CustomMessages::ReservationReminder).not_to receive(:perform_at)

            outcome
          end
        end
      end
    end
  end
end
