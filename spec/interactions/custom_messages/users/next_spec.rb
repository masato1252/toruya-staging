# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Users::Next do
  let(:prev_custom_message) { FactoryBot.create(:custom_message, :user_signed_up_scenario, service: service, after_days: prev_after_days) }
  let(:scenario) { nil }
  let(:prev_after_days) { nil }
  let(:service) { nil }
  let(:receiver) { FactoryBot.create(:user) }
  # CustomMessages::Users::Template::USER_SIGN_UP scenario
  let(:scenario_start_at) { receiver.created_at }
  let(:args) do
    {
      receiver: receiver,
      custom_message: prev_custom_message,
      scenario: scenario
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

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9),
          scenario_start_at: scenario_start_at,
          custom_message: next_custom_message1,
          receiver: receiver
        })

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9),
          scenario_start_at: scenario_start_at,
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

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9),
          scenario_start_at: scenario_start_at,
          custom_message: next_custom_message1,
          receiver: receiver
        })

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9),
          scenario_start_at: scenario_start_at,
          custom_message: next_custom_message2,
          receiver: receiver
        })

        outcome
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
        expect(Notifiers::Users::CustomMessages::Send).not_to receive(:perform_at)

        outcome
      end
    end

    context "when it was from new/updated custom_message" do
      let(:current_custom_message) { FactoryBot.create(:custom_message, :user_signed_up_scenario, after_days: 3) }
      let(:args) do
        {
          receiver: receiver,
          custom_message: current_custom_message,
          schedule_right_away: true
        }
      end

      it "schedules the next custom message" do
        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: scenario_start_at.advance(days: current_custom_message.after_days).change(hour: 9),
          scenario_start_at: scenario_start_at,
          custom_message: current_custom_message,
          receiver: receiver
        })

        outcome
      end
    end

    context "when it is from first time user sign up" do
      let(:new_custom_message_after_days ) { 0 }
      let(:custom_message) { nil }
      let(:scenario) { CustomMessages::Users::Template::USER_SIGN_UP }
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

          expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
            schedule_at: scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9),
            scenario_start_at: scenario_start_at,
            custom_message: next_custom_message1,
            receiver: receiver
          })

          expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).with({
            schedule_at: scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9),
            scenario_start_at: scenario_start_at,
            custom_message: next_custom_message2,
            receiver: receiver
          })

          outcome
        end
      end

      context "when there is NO next custom message" do
        it "does nothing" do
          expect(Notifiers::Users::CustomMessages::Send).not_to receive(:perform_at)

          outcome
        end
      end
    end
  end
end
