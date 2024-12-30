# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Property do
  let(:user) { subscription.user }
  let(:args) do
    {
      user: user,
      plan: plan,
    }
  end
  let(:outcome) { described_class.run!(args) }

  RSpec.shared_examples "plan property" do |plan_level, property|
    let(:plan) { Plan.public_send(plan_level).take }

    context "when plan is #{plan_level} plan" do
      it "returns expected property" do
        expect(outcome).to eq(property)
      end
    end
  end

  describe "#execute" do
    context "when user is regular user" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      it_behaves_like "plan property", :free_level,
        Hashie::Mash.new({
        level: "free",
        key: "free",
        selectable: true,
        name: I18n.t("plan.level.free"),
        details: I18n.t("plans")[:free].dup.merge!(
          customer_number: I18n.t("plans.free.customer_number", customer_limit:  Plan.max_customers_limit(Plan::FREE_LEVEL, 0)),
        )
      })

      it_behaves_like "plan property", :basic_level,
        Hashie::Mash.new({
        level: "basic",
        key: "basic",
        selectable: true,
        name: I18n.t("plan.level.basic"),
        details: I18n.t("plans")[:basic].dup.merge!(
          customer_number: I18n.t("plans.basic.customer_number", customer_limit:  Plan.max_customers_limit(Plan::BASIC_LEVEL, 0)),
          ranks: Plan.plans[Plan::BASIC_LEVEL].map { |rank_context| rank_context.merge!(costFormat: rank_context[:cost].to_money.format) }
        )
      })
    end

    xcontext "when user is business member" do
      let(:subscription) { FactoryBot.create(:subscription, :business) }

      it_behaves_like "plan property", :business_level,
        Hashie::Mash.new({
        level: "premium",
        key: "business",
        selectable: true,
        cost: 55_000,
        costWithFee: 63_800,
        costFormat: "¥55,000",
        name: I18n.t("plan.level.business"),
        details: I18n.t("settings.plans")[:business]
      })
    end

    xcontext "when user is child member" do
      context "when user was never be charged before" do
        let!(:referral) { factory.create_referral(state: :pending, referrer: user) }
        let(:subscription) { FactoryBot.create(:subscription, :free) }

        it_behaves_like "plan property", :free_level,
          Hashie::Mash.new({
            level: "free",
            key: "free",
            selectable: false,
            cost: 0,
            costWithFee: 0,
            costFormat: "¥0",
            name: I18n.t("plan.level.free"),
            details: I18n.t("settings.plans")[:free]
          })

        it_behaves_like "plan property", :child_basic_level,
          Hashie::Mash.new({
            level: "basic",
            key: "child_basic",
            selectable: true,
            cost: 19_800,
            costWithFee: 19_800,
            costFormat: "¥19,800",
            name: I18n.t("plan.level.child_basic"),
            details: I18n.t("settings.plans")[:child_basic]
          })

        it_behaves_like "plan property", :child_premium_level,
          Hashie::Mash.new({
            level: "premium",
            key: "child_premium",
            selectable: true,
            cost: 49_500,
            costWithFee: 49_500,
            costFormat: "¥49,500",
            name: I18n.t("plan.level.child_premium"),
            details: I18n.t("settings.plans")[:child_premium]
          })
      end

      context "when user ever be charged before" do
        before do
          FactoryBot.create(:subscription_charge, :completed, user: user)
        end

        let!(:referral) { factory.create_referral(state: :active, referrer: user) }
        let(:subscription) { FactoryBot.create(:subscription, :child_basic) }

        it_behaves_like "plan property", :free_level,
          Hashie::Mash.new({
          level: "free",
          key: "free",
          selectable: true,
          cost: 0,
          costWithFee: 0,
          costFormat: "¥0",
          name: I18n.t("plan.level.free"),
          details: I18n.t("settings.plans")[:free]
        })

        it_behaves_like "plan property", :child_basic_level,
          Hashie::Mash.new({
          level: "basic",
          key: "child_basic",
          selectable: true,
          cost: 22_000,
          costWithFee: 22_000,
          costFormat: "¥22,000",
          name: I18n.t("plan.level.child_basic"),
          details: I18n.t("settings.plans")[:child_basic]
        })

        it_behaves_like "plan property", :child_premium_level,
          Hashie::Mash.new({
          level: "premium",
          key: "child_premium",
          selectable: true,
          cost: 55_000,
          costWithFee: 55_000,
          costFormat: "¥55,000",
          name: I18n.t("plan.level.child_premium"),
          details: I18n.t("settings.plans")[:child_premium]
        })
      end
    end
  end
end
