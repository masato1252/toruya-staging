# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Customers::Next do
  let(:prev_custom_message) { FactoryBot.create(:custom_message, service: service, after_days: prev_after_days) }
  let(:prev_after_days) { nil }
  let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  let(:service) { relation.online_service }
  let(:receiver) { relation.customer }
  let(:args) do
    {
      receiver: receiver,
      custom_message: prev_custom_message
    }
  end
  let(:outcome) { described_class.run(args) }
  let(:customer_timezone) { ::LOCALE_TIME_ZONE[receiver.locale] || "Asia/Tokyo" }
  let(:notification_hour) { described_class::DEFAULT_NOTIFICATION_HOUR }

  # Helper method to calculate expected schedule time in customer's timezone
  def expected_schedule_time(base_time, days)
    Time.use_zone(customer_timezone) do
      base = base_time.advance(days: days)
      base.change(hour: notification_hour, min: 0, sec: 0)
    end
  end

  describe "#execute" do
    context "when there is after days 0 message" do
      let(:new_custom_message_after_days) { 0 }

      it "schedules the next custom message" do
        next_custom_message1, next_custom_message2 = FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )

        expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at).twice do |args|
          base_time = service.start_at_for_customer(receiver)
          expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, next_custom_message1.after_days))
          expect([next_custom_message1, next_custom_message2]).to include(args[:custom_message])
          expect(args[:receiver]).to eq(receiver)
        end

        outcome
      end
    end

    context "when there is next custom message" do
      let(:prev_after_days) { 0 }
      let(:new_custom_message_after_days) { prev_after_days + 1 }

      it "schedules the next custom message" do
        next_custom_message1, next_custom_message2 = FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )

        expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at).twice do |args|
          base_time = service.start_at_for_customer(receiver)
          expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, next_custom_message1.after_days))
          expect([next_custom_message1, next_custom_message2]).to include(args[:custom_message])
          expect(args[:receiver]).to eq(receiver)
        end

        outcome
      end

      context "when next custom_message schedule time was passed" do
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: FactoryBot.create(:online_service, start_at: 3.days.ago)) }

        it "doesn't schedule next custom message" do
          FactoryBot.create_list(
            :custom_message,
            2,
            service: service,
            scenario: prev_custom_message.scenario,
            after_days: new_custom_message_after_days
          )

          expect(Notifiers::Customers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end
    end

    context "when there is NO next custom message" do
      let(:prev_after_days) { 2 }
      let(:new_custom_message_after_days) { prev_after_days - 1 }

      it "does nothing" do
        FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )
        expect(Notifiers::Customers::CustomMessages::Send).not_to receive(:perform_at)

        outcome
      end
    end

    context "when it was from new/updated custom_message" do
      let(:current_custom_message) { FactoryBot.create(:custom_message, service: service, after_days: 3) }
      let(:args) do
        {
          receiver: receiver,
          custom_message: current_custom_message,
          schedule_right_away: true
        }
      end

      it "schedules the next custom message" do
        expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at) do |args|
          base_time = service.start_at_for_customer(receiver)
          expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, current_custom_message.after_days))
          expect(args[:custom_message]).to eq(current_custom_message)
          expect(args[:receiver]).to eq(receiver)
        end

        outcome
      end

      context "when the new custom_message's after_days time was pass(before Time.current)" do
        # The online_service start 4 days ago, but this new message was for after service started 3 days
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: FactoryBot.create(:online_service, start_at: 4.days.ago)) }

        it "does nothing" do
          expect(Notifiers::Customers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end

      context "when the new custom_message's after_days time was not pass(before Time.current)" do
        # The online_service start 2 days ago(customer join), and this new message was for after service started 3 days
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, created_at: 2.days.ago) }

        it "schedules the next custom message" do
          expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at) do |args|
            base_time = service.start_at_for_customer(receiver)
            expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, current_custom_message.after_days))
            expect(args[:custom_message]).to eq(current_custom_message)
            expect(args[:receiver]).to eq(receiver)
          end

          outcome
        end
      end
    end

    context "when it is from first time customer purchased(without custom_message params)" do
      let(:new_custom_message_after_days) { 2 }
      let(:scenario) { CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED }
      let(:args) do
        {
          receiver: receiver,
          product: service,
          scenario: scenario
        }
      end

      context "when there is next custom message" do
        it "schedules the next custom message" do
          next_custom_message1, next_custom_message2 = FactoryBot.create_list(
            :custom_message,
            2,
            service: service,
            scenario: scenario,
            after_days: new_custom_message_after_days
          )

          expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at).twice do |args|
            base_time = service.start_at_for_customer(receiver)
            expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, next_custom_message1.after_days))
            expect([next_custom_message1, next_custom_message2]).to include(args[:custom_message])
            expect(args[:receiver]).to eq(receiver)
          end

          outcome
        end
      end

      context "when there is NO next custom message" do
        it "does nothing" do
          expect(Notifiers::Customers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end
    end

    context "with schedule_right_away parameter" do
      let(:current_custom_message) { FactoryBot.create(:custom_message, service: service, after_days: 3) }
      let(:args) do
        {
          receiver: receiver,
          custom_message: current_custom_message,
          schedule_right_away: true
        }
      end

      it "schedules the message immediately" do
        expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at) do |args|
          base_time = service.start_at_for_customer(receiver)
          expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, current_custom_message.after_days))
          expect(args[:custom_message]).to eq(current_custom_message)
          expect(args[:receiver]).to eq(receiver)
        end

        outcome
      end

      context "when the message time has already passed" do
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: FactoryBot.create(:online_service, start_at: 4.days.ago)) }

        it "does not schedule the message" do
          expect(Notifiers::Customers::CustomMessages::Send).not_to receive(:perform_at)
          outcome
        end
      end

      context "when the message time has not passed" do
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, created_at: 2.days.ago) }

        it "schedules the message" do
          expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at) do |args|
            base_time = service.start_at_for_customer(receiver)
            expect(args[:schedule_at].change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, current_custom_message.after_days))
            expect(args[:custom_message]).to eq(current_custom_message)
            expect(args[:receiver]).to eq(receiver)
          end

          outcome
        end
      end
    end

    context "with different timezones" do
      let(:prev_after_days) { 0 }
      let(:new_custom_message_after_days) { prev_after_days + 1 }

      [:ja, :tw].each do |test_locale|
        context "when customer locale is #{test_locale}" do
          let(:customer_timezone) { ::LOCALE_TIME_ZONE[test_locale] || "Asia/Tokyo" }

          before do
            allow(receiver).to receive(:locale).and_return(test_locale)
            allow(receiver).to receive(:timezone).and_return(customer_timezone)
          end

          it "schedules messages in customer's timezone" do
            next_custom_message = FactoryBot.create(
              :custom_message,
              service: service,
              scenario: prev_custom_message.scenario,
              after_days: new_custom_message_after_days,
              locale: test_locale
            )

            expect(Notifiers::Customers::CustomMessages::Send).to receive(:perform_at) do |args|
              base_time = service.start_at_for_customer(receiver)
              scheduled_time = args[:schedule_at]

              # Verify schedule time is correct in customer's timezone
              Time.use_zone(customer_timezone) do
                expect(scheduled_time.hour).to eq(notification_hour)
                expect(scheduled_time.change(min: 0, sec: 0)).to eq(expected_schedule_time(base_time, next_custom_message.after_days))
              end

              expect(args[:custom_message]).to eq(next_custom_message)
              expect(args[:receiver]).to eq(receiver)
            end

            outcome
          end
        end
      end
    end
  end
end
