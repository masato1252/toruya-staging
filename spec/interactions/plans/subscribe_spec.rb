require "rails_helper"

RSpec.describe Plans::Subscribe do
  let(:user) { FactoryBot.create(:user) }
  let(:plan) { Plan.free_level.take }
  let(:authorize_token) { SecureRandom.hex }
  let(:upgrade_immediately) { true }
  let(:args) do
    {
      user: user,
      plan: plan,
      authorize_token: authorize_token,
      upgrade_immediately: upgrade_immediately
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when users don't have a subscription yet" do
      context "when users want to subscribe free plan" do
        it "subscribes free plan directly" do
          outcome

          expect(user.subscription.reload.plan).to be_free_level
        end
      end

      context "when users want to subscribe paid plan" do
        let(:plan) { Plan.basic_level.take }
        let(:subscription) { user.build_subscription }
        before do
          allow(user).to receive(:build_subscription).and_return(subscription)
          user.reload
        end

        it "charges directly" do
          allow(Subscriptions::ManualCharge).to receive(:run).and_return(spy(valid?: true))

          outcome

          expect(Subscriptions::ManualCharge).to have_received(:run) do
            expect(args[:plan]).to eq(plan)
            expect(args[:authorize_token]).to eq(authorize_token)
          end
        end
      end
    end

    context "when users had a subscription" do
      let!(:subscription) { FactoryBot.create(:subscription, :free, user: user) }

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
          let(:upgrade_immediately) { false }

          it "stays the current plan and updates the next plan" do
            outcome

            subscription = user.subscription.reload

            expect(subscription.plan).to be_free_level
            expect(subscription.next_plan).to be_basic_level
          end
        end
      end

      context "when users want to downgrade their plans" do
        let!(:subscription) { FactoryBot.create(:subscription, :premium, user: user) }
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
end
