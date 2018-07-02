require "rails_helper"

RSpec.describe Subscriptions::RecurringCharge do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:args) do
    {
      subscription: subscription
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when users change their plans" do
      let(:subscription) { FactoryBot.create(:subscription, :premium, next_plan: next_plan) }
      let(:next_plan) { Plan.free_level.take }

      it "changes subscription to next plan" do
        outcome

        subscription.reload
        expect(subscription.plan).to eq(next_plan)
        expect(subscription.next_plan).to be_nil
      end
    end

    context "when the plan is free" do
      it "charges nothing" do
        expect(Subscriptions::Charge).not_to receive(:run)

        outcome
      end
    end

    context "when the paid need to be charged" do
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(Date.new(2018, 1, 31))
        StripeMock.start
      end
      after { StripeMock.stop }
      let(:subscription) { FactoryBot.create(:subscription, :premium) }

      it "charges user" do
        allow(SubscriptionMailer).to receive(:charge_successfully).with(subscription).and_return(double(deliver_now: true))
        outcome

        subscription.reload
        expect(subscription.plan).to eq(Plan.premium_level.take)
        expect(subscription.next_plan).to be_nil
        expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
        expect(SubscriptionMailer).to have_received(:charge_successfully).with(subscription)
      end

      context "when charging users failed" do
        let(:subscription) { FactoryBot.create(:subscription, :basic, next_plan: Plan.premium_level.take) }
        before do
          StripeMock.prepare_card_error(:card_declined)
        end

        # [TODO]: notify users?
        it "doesn't change subscription" do
          expect(SubscriptionMailer).not_to receive(:charge_successfully)

          outcome

          subscription.reload
          expect(subscription.plan).to eq(Plan.basic_level.take)
          expect(subscription.next_plan).to eq(Plan.premium_level.take)
          expect(subscription.expired_date).to eq(subscription.expired_date)
        end
      end
    end
  end
end
