# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Properties do
  let(:user) { subscription.user }
  let(:args) do
    {
      user: user,
    }
  end
  let(:outcome) { described_class.run!(args) }

  describe "#execute" do
    context "when user is regular user" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      it "returns expected result" do
        expect(outcome).to eq({
          Plan::FREE_PLAN => Plans::Property.run!(user: user, plan: Plan.free_level.take),
          Plan::BASIC_PLAN => Plans::Property.run!(user: user, plan: Plan.basic_level.take)
        })
      end
    end

    xcontext "when user is business member" do
      let(:subscription) { FactoryBot.create(:subscription, :business) }

      it "returns expected result" do
        expect(outcome).to eq({
          Plan::FREE_PLAN => Hashie::Mash.new({
            level: "free",
            key: "free",
            selectable: true,
            cost: 0,
            costWithFee: 0,
            costFormat: "¥0",
            name: Plan.free_level.take.name,
            details: I18n.t("settings.plans")[:free]
          }),
          Plan::BASIC_PLAN => Hashie::Mash.new({
            level: "basic",
            key: "basic",
            selectable: true,
            cost: 2_200,
            costWithFee: 2_200,
            costFormat: "¥2,200",
            name: Plan.basic_level.take.name,
            details: I18n.t("settings.plans")[:basic]
          }),
          Plan::PREMIUM_PLAN => Hashie::Mash.new({
            level: "premium",
            key: "business",
            selectable: true,
            cost: 55_000,
            costWithFee: 63_800,
            costFormat: "¥55,000",
            name: Plan.business_level.take.name,
            details: I18n.t("settings.plans")[:business]
          })
        })
      end
    end

    xcontext "when user is child member" do
      context "when user was never be charged before" do
        let!(:referral) { factory.create_referral(state: :pending, referrer: user) }
        let(:subscription) { FactoryBot.create(:subscription, :free) }

        it "returns expected result" do
          expect(outcome).to eq({
            Plan::FREE_PLAN => Hashie::Mash.new({
              level: "free",
              key: "free",
              selectable: false,
              cost: 0,
              costWithFee: 0,
              costFormat: "¥0",
              name: Plan.free_level.take.name,
              details: I18n.t("settings.plans")[:free]
            }),
            Plan::BASIC_PLAN => Hashie::Mash.new({
              level: "basic",
              key: "child_basic",
              selectable: true,
              cost: 19_800,
              costWithFee: 19_800,
              costFormat: "¥19,800",
              name: Plan.child_basic_level.take.name,
              details: I18n.t("settings.plans")[:child_basic]
            }),
            Plan::PREMIUM_PLAN => Hashie::Mash.new({
              level: "premium",
              key: "child_premium",
              selectable: true,
              cost: 49_500,
              costWithFee: 49_500,
              costFormat: "¥49,500",
              name: Plan.child_premium_level.take.name,
              details: I18n.t("settings.plans")[:child_premium]
            })
          })
        end
      end

      context "when user ever be charged before" do
        before do
          FactoryBot.create(:subscription_charge, :completed, user: user)
        end

        let!(:referral) { factory.create_referral(state: :active, referrer: user) }
        let(:subscription) { FactoryBot.create(:subscription, :child_basic) }

        it "returns expected result" do
          expect(outcome).to eq({
            Plan::FREE_PLAN => Hashie::Mash.new({
              level: "free",
              key: "free",
              selectable: true,
              cost: 0,
              costWithFee: 0,
              costFormat: "¥0",
              name: Plan.free_level.take.name,
              details: I18n.t("settings.plans")[:free]
            }),
            Plan::BASIC_PLAN => Hashie::Mash.new({
              level: "basic",
              key: "child_basic",
              selectable: true,
              cost: 22_000,
              costWithFee: 22_000,
              costFormat: "¥22,000",
              name: Plan.child_basic_level.take.name,
              details: I18n.t("settings.plans")[:child_basic]
            }),
            Plan::PREMIUM_PLAN => Hashie::Mash.new({
              level: "premium",
              key: "child_premium",
              selectable: true,
              cost: 55_000,
              costWithFee: 55_000,
              costFormat: "¥55,000",
              name: Plan.child_premium_level.take.name,
              details: I18n.t("settings.plans")[:child_premium]
            })
          })
        end
      end
    end
  end
end
