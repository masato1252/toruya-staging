# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Users::Next do
  let(:prev_custom_message) { FactoryBot.create(:custom_message, :user_signed_up_scenario, service: service, after_days: prev_after_days) }
  let(:scenario) { nil }
  let(:nth_time) { nil }
  let(:prev_after_days) { nil }
  let(:service) { nil }
  let(:receiver) { FactoryBot.create(:user) }
  # CustomMessages::Users::Template::USER_SIGN_UP scenario
  let(:scenario_start_at) { receiver.created_at }
  let(:args) do
    {
      receiver: receiver,
      custom_message: prev_custom_message,
      scenario: scenario,
      nth_time: nth_time
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

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
          expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9))
          expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
          expect(args[:custom_message]).to eq(next_custom_message1)
          expect(args[:receiver]).to eq(receiver)
        end

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
          expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9))
          expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
          expect(args[:custom_message]).to eq(next_custom_message2)
          expect(args[:receiver]).to eq(receiver)
        end

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

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
          expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9))
          expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
          expect(args[:custom_message]).to eq(next_custom_message1)
          expect(args[:receiver]).to eq(receiver)
        end

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
          expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9))
          expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
          expect(args[:custom_message]).to eq(next_custom_message2)
          expect(args[:receiver]).to eq(receiver)
        end

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
        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
          expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: current_custom_message.after_days).change(hour: 9))
          expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
          expect(args[:custom_message]).to eq(current_custom_message)
          expect(args[:receiver]).to eq(receiver)
        end

        outcome
      end
    end

    context "when it is from first time user sign up" do
      let(:new_custom_message_after_days ) { 0 }
      let(:custom_message) { nil }
      let(:scenario) { CustomMessages::Users::Template::USER_SIGN_UP }
      let(:nth_time) { 1 }
      let(:args) do
        {
          receiver: receiver,
          product: service,
          scenario: scenario,
          nth_time: nth_time
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
          expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
            expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message1.after_days).change(hour: 9))
            expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
            expect(args[:custom_message]).to eq(next_custom_message1)
            expect(args[:receiver]).to eq(receiver)
          end

          expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at) do |args|
            expect(args[:schedule_at]).to be_within(10.minutes).of(scenario_start_at.advance(days: next_custom_message2.after_days).change(hour: 9))
            expect(args[:scenario_start_at]).to be_within(10.minutes).of(scenario_start_at)
            expect(args[:custom_message]).to eq(next_custom_message2)
            expect(args[:receiver]).to eq(receiver)
          end

          outcome

          expect(outcome).to be_valid
        end
      end

      context "when there is NO next custom message" do
        it "does nothing" do
          expect(Notifiers::Users::CustomMessages::Send).not_to receive(:perform_at)

          outcome

          expect(outcome).to be_valid
        end
      end
    end
  end
end
