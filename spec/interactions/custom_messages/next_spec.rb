# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Next do
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

  describe "#execute" do
    context "when there is after days 0 message" do
      let(:new_custom_message_after_days ) { 0 }

      it "schedules the next custom message" do
        next_custom_message1, next_custom_message2 = FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )

        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message1.after_days).change(hour: 9),
          custom_message: next_custom_message1,
          receiver: receiver
        })

        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message2.after_days).change(hour: 9),
          custom_message: next_custom_message2,
          receiver: receiver
        })

        outcome
      end
    end

    context "when there is next custom message" do
      let(:prev_after_days ) { 0 }
      let(:new_custom_message_after_days ) { prev_after_days + 1 }

      it "schedules the next custom message" do
        next_custom_message1, next_custom_message2 = FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )

        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message1.after_days).change(hour: 9),
          custom_message: next_custom_message1,
          receiver: receiver
        })

        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message2.after_days).change(hour: 9),
          custom_message: next_custom_message2,
          receiver: receiver
        })

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

          expect(Notifiers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end
    end

    context "when there is NO next custom message" do
      let(:prev_after_days ) { 2 }
      let(:new_custom_message_after_days ) { prev_after_days - 1 }

      it "does nothing" do
        FactoryBot.create_list(
          :custom_message,
          2,
          service: service,
          scenario: prev_custom_message.scenario,
          after_days: new_custom_message_after_days
        )
        expect(Notifiers::CustomMessages::Send).not_to receive(:perform_at)

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
        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: service.start_at_for_customer(receiver).advance(days: current_custom_message.after_days).change(hour: 9),
          custom_message: current_custom_message,
          receiver: receiver
        })

        outcome
      end

      context "when the new custom_message's after_days time was pass(before Time.current)" do
        # The online_service start 4 days ago, but this new message was for after service started 3 days
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: FactoryBot.create(:online_service, start_at: 4.days.ago)) }

        it "does nothing" do
          expect(Notifiers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end

      context "when the new custom_message's after_days time was not pass(before Time.current)" do
        # The online_service start 2 days ago(customer join), and this new message was for after service started 3 days
        let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free, created_at: 2.days.ago) }

        it "schedules the next custom message" do
          expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
            schedule_at: service.start_at_for_customer(receiver).advance(days: current_custom_message.after_days).change(hour: 9),
            custom_message: current_custom_message,
            receiver: receiver
          })

          outcome
        end
      end
    end

    context "when it is from first time customer purchased(without custom_message params)" do
      let(:new_custom_message_after_days ) { 0 }
      let(:custom_message) { nil }
      let(:scenario) { "foo" }
      let(:args) do
        {
          receiver: receiver,
          product: service,
          scenario: scenario
        }
      end

      context "when there is next custom message" do
        let(:new_custom_message_after_days ) { 2 }

        it "schedules the next custom message" do
          next_custom_message1, next_custom_message2 = FactoryBot.create_list(
            :custom_message,
            2,
            service: service,
            scenario: scenario,
            after_days: new_custom_message_after_days
          )

          expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
            schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message1.after_days).change(hour: 9),
            custom_message: next_custom_message1,
            receiver: receiver
          })

          expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
            schedule_at: service.start_at_for_customer(receiver).advance(days: next_custom_message2.after_days).change(hour: 9),
            custom_message: next_custom_message2,
            receiver: receiver
          })

          outcome
        end
      end

      context "when there is NO next custom message" do
        it "does nothing" do
          expect(Notifiers::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end
    end
  end
end
