# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::ShopFeeProration do
  let(:user) { subscription.user }
  let(:subscription) { FactoryBot.create(:subscription, :premium) }

  before do
    Time.zone = "Tokyo"
  end

  after { Timecop.return }

  describe "#execute" do
    context "when user is in paid plan with billing cycle" do
      before do
        Timecop.freeze(Date.new(2018, 1, 15))
        subscription.update!(expired_date: Date.new(2018, 2, 1), recurring_day: 1)
      end

      it "returns prorated amount for one shop over the full billing cycle" do
        result = described_class.run!(user: user)

        expect(result[:amount]).to eq(Money.new(550, :jpy) * Rational(17, 31))
        expect(result[:monthly_fee]).to eq(Money.new(550, :jpy))
        expect(result[:period_start]).to eq(Date.new(2018, 1, 15))
        expect(result[:period_end]).to eq(Date.new(2018, 1, 31))
      end
    end

    context "when the latest plan charge covers only a short upgrade window" do
      before do
        Timecop.freeze(Date.new(2026, 6, 1))
        subscription.update!(expired_date: Date.new(2026, 6, 5), recurring_day: 5)
        FactoryBot.create(
          :subscription_charge,
          :completed,
          :plan_subscruption,
          user: user,
          plan: subscription.plan,
          charge_date: Date.new(2026, 6, 4),
          expired_date: Date.new(2026, 6, 5),
          amount_cents: 5500
        )
      end

      it "prorates only the 550 yen shop fee across the subscription billing cycle" do
        result = described_class.run!(user: user)

        expect(result[:amount]).to eq(Money.new(550, :jpy) * Rational(4, 31))
        expect(result[:monthly_fee]).to eq(Money.new(550, :jpy))
      end
    end

    context "when recurring_day is nil" do
      before do
        Timecop.freeze(Date.new(2026, 6, 1))
        subscription.update!(expired_date: Date.new(2026, 6, 5), recurring_day: nil)
      end

      it "falls back to expired_date day and does not raise error" do
        result = described_class.run!(user: user)

        expect(result[:amount]).to eq(Money.new(550, :jpy) * Rational(4, 31))
      end
    end

    context "when calculated cycle days are unexpectedly too short" do
      before do
        Timecop.freeze(Date.new(2026, 6, 1))
        subscription.update!(expired_date: Date.new(2026, 6, 5), recurring_day: 5)
        allow_any_instance_of(described_class).to receive(:billing_period_days).and_return(1)
      end

      it "caps prorated amount at one month fee" do
        result = described_class.run!(user: user)

        expect(result[:amount]).to eq(Money.new(550, :jpy))
      end
    end

    context "when user is not in paid plan" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      before { Timecop.freeze(Date.new(2018, 1, 15)) }

      it "returns full monthly fee for one shop" do
        result = described_class.run!(user: user)

        expect(result[:amount]).to eq(Money.new(550, :jpy))
      end
    end
  end
end
