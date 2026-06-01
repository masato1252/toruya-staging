# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Fee do
  let(:user) { subscription.user }
  let(:plan) { subscription.plan }

  describe "#execute" do
    context "when user has one shop on premium plan" do
      let(:subscription) { FactoryBot.create(:subscription, :premium) }

      before { FactoryBot.create(:shop, user: user) }

      it "returns zero" do
        expect(described_class.run!(user: user, plan: plan)).to eq(Money.zero(:jpy))
      end
    end

    context "when user has two shops on premium plan" do
      let(:subscription) { FactoryBot.create(:subscription, :premium) }

      before do
        FactoryBot.create(:shop, user: user)
        FactoryBot.create(:shop, user: user)
      end

      it "returns fee for one extra shop" do
        expect(described_class.run!(user: user, plan: plan)).to eq(Money.new(550, :jpy))
      end
    end

    context "when user is on free plan" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      before do
        FactoryBot.create(:shop, user: user)
        FactoryBot.create(:shop, user: user)
      end

      it "returns zero" do
        expect(described_class.run!(user: user, plan: plan)).to eq(Money.zero(:jpy))
      end
    end

    context "when user is on enterprise plan" do
      let(:subscription) { FactoryBot.create(:subscription, plan: Plan.enterprise_level.take) }

      before do
        FactoryBot.create(:shop, user: user)
        FactoryBot.create(:shop, user: user)
      end

      it "returns zero" do
        expect(described_class.run!(user: user, plan: plan)).to eq(Money.zero(:jpy))
      end
    end
  end
end
