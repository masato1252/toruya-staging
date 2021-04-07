# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Subscribe do
  let(:user) { subscription.user }
  let(:plan) { Plan.free_level.take }
  let(:rank) { 0 }
  let(:authorize_token) { SecureRandom.hex }
  let(:change_immediately) { true }
  let(:args) do
    {
      user: user,
      plan: plan,
      rank: rank,
      authorize_token: authorize_token,
      change_immediately: change_immediately
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    let!(:subscription) { FactoryBot.create(:subscription, :free) }

    context "when subscription is active and subscribe the same plan again" do
      let(:plan) { subscription.plan }

      it "adds a error" do
        expect(outcome.errors.details[:plan]).to include(error: :already_subscribe_the_same_plan)
      end
    end

    context "when users want to upgrade their plans" do
      let(:plan) { Plan.basic_level.take }

      context "user want to upgrade immediately" do
        it "charges user and upgrade plan immediately" do
          allow(Subscriptions::ManualCharge).to receive(:run).and_return(spy(valid?: true))

          outcome

          expect(Subscriptions::ManualCharge).to have_received(:run) do
            expect(args[:plan]).to eq(plan)
            expect(args[:authorize_token]).to eq(authorize_token)
          end
        end
      end

      context "user want to upgrade in next charge period" do
        let(:change_immediately) { false }

        it "stays the current plan and updates the next plan" do
          outcome

          subscription = user.subscription.reload

          expect(subscription.plan).to be_free_level
          expect(subscription.next_plan).to be_basic_level
        end
      end
    end

    context "when users want to downgrade their plans" do
      let!(:subscription) { FactoryBot.create(:subscription, :premium) }
      let(:plan) { Plan.basic_level.take }

      it "stays the current plan and updates the next plan" do
        outcome

        subscription = user.subscription.reload

        expect(subscription.plan).to be_premium_level
        expect(subscription.next_plan).to be_basic_level
      end
    end
  end
end
