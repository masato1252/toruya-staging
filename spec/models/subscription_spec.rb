# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscription do
  let(:subscription) { FactoryBot.create(:subscription) }

  describe "#active?" do
    before do
      Time.zone = "Tokyo"
      Timecop.freeze(Date.new(2022, 5, 15))
    end

    context "when subscription is free plan" do
      let(:subscription) { FactoryBot.create(:subscription, plan_id: Subscription::FREE_PLAN_ID) }

      context "when trial hasn't expired" do
        before do
          subscription.update(trial_expired_date: Date.new(2022, 5, 20))
        end

        it "returns true" do
          expect(subscription.active?).to be true
        end
      end

      context "when trial has expired" do
        before do
          # Make sure the trial has expired
          subscription.update(trial_expired_date: Date.new(2022, 5, 10))
          # Explicitly stub both conditions that could make a free plan active
          allow(subscription).to receive(:customers_count_over_free_limit?).and_return(true)
          allow(subscription).to receive(:in_free_plan?).and_return(true)
          # Ensure we don't have a valid expiration date condition either
          subscription.update(expired_date: nil)
        end

        it "returns false when all conditions for being active are false" do
          # With trial expired, over free limit, and no valid expiration date
          # All three conditions in active? should evaluate to false
          expect(subscription.active?).to be false
        end
      end
    end

    context "when subscription is paid plan" do
      let(:subscription) { FactoryBot.create(:subscription, plan_id: 2) } # Assuming 2 is a paid plan ID

      context "when expired_date is in the future" do
        before do
          subscription.update(expired_date: Date.new(2022, 6, 15))
        end

        it "returns true" do
          expect(subscription.active?).to be true
        end
      end

      context "when expired_date is today" do
        before do
          subscription.update(expired_date: Date.new(2022, 5, 15))
        end

        it "returns true" do
          expect(subscription.active?).to be true
        end
      end

      context "when expired_date is within the buffer period" do
        before do
          # Use a date exactly at the buffer threshold
          buffer_date = Date.new(2022, 5, 13)
          subscription.update(expired_date: buffer_date)
          # Make sure this isn't a free plan so we test only the buffer condition
          allow(subscription).to receive(:in_free_plan?).and_return(false)
        end

        it "returns true" do
          # 2022-05-15 + INACTIVE_BUFFER_DAYS(-2) = 2022-05-13
          # So 2022-05-13 is exactly at the buffer threshold and should be active
          expect(subscription.active?).to be true
        end

        it "considers subscriptions within INACTIVE_BUFFER_DAYS as active" do
          # Directly test that the buffer logic works as expected
          expect(subscription.expired_date).to eq(Date.new(2022, 5, 13))
          expect(Date.new(2022, 5, 15).advance(days: Subscription::INACTIVE_BUFFER_DAYS)).to eq(Date.new(2022, 5, 13))
          expect(subscription.active?).to be true
        end
      end

      context "when expired_date is before the buffer period" do
        before do
          subscription.update(trial_expired_date: Date.new(2022, 5, 10)) # make trial expired
          allow(subscription).to receive(:customers_count_over_free_limit?).and_return(true)
          subscription.update(expired_date: Date.new(2022, 5, 12))
        end

        it "returns false" do
          expect(subscription.active?).to be false
        end
      end

      context "when expired_date is nil" do
        before do
          subscription.update(trial_expired_date: Date.new(2022, 5, 10)) # make trial expired
          allow(subscription).to receive(:customers_count_over_free_limit?).and_return(true)
          subscription.update(expired_date: nil)
        end

        it "returns false" do
          expect(subscription.active?).to be false
        end
      end
    end
  end

  describe "#set_recurring_day" do
    it "sets today's day" do
      subscription.set_recurring_day

      expect(subscription.recurring_day).to eq(described_class.today.day)
    end
  end

  describe "#set_expire_date" do
    context "when user have paid their subscription" do
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(charge_date)
      end

      let!(:last_completed_charge) { FactoryBot.create(:subscription_charge, :completed, charge_date: charge_date, user: subscription.user) }

      context "when the recurring_day is over the end of month" do
        let(:charge_date) { Date.new(2017, 12, 31) }

        it "sets the expired date to last charge date's end of next month" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
        end
      end

      context "when the recurring_day is less or equal than the end of month" do
        let(:charge_date) { Date.new(2017, 12, 27) }

        it "sets the expired date to next charge date" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(Date.new(2018, 2, 27))
        end
      end

      context "when plan is an annual plan" do
        let(:subscription) { FactoryBot.create(:subscription, :business) }
        let(:charge_date) { Date.new(2018, 1, 31) }

        it "sets the expired date to next charge date" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
        end
      end

      context "when user be charged before current expire date expired" do
        let(:charge_date) { Date.new(2021, 3, 23) }
        let(:last_charge_date) { charge_date.advance(weeks: -2) }
        let!(:last_completed_charge) { FactoryBot.create(:subscription_charge, :completed, charge_date: last_charge_date, user: subscription.user) }

        it "sets expired date from last record's expire date" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(last_completed_charge.expired_date.next_month)
        end
      end
    end

    context "when users never paid their subscription" do
      it "sets today" do
        subscription.set_expire_date

        expect(subscription.expired_date).to eq(described_class.today)
      end
    end
  end

  describe "#next_period" do
    context "when expired_date was passed" do
      let(:today) { Date.new(2019, 1, 1) }
      let(:expired_period_end_date) { Date.new(2019, 2, 1) }
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(today)
      end
      it "uses Today's date to returns expected period" do
        [
          [Date.new(2018, 1, 1), Date.new(2018, 2, 1)],
        ].each do |expired_date, expected_next_end_date|
          subscription = FactoryBot.create(:subscription, expired_date: expired_date, recurring_day: expired_date.day)

          expect(subscription.next_period).to eq(today..expired_period_end_date)
        end
      end
    end
    context "when expired_date is in the future" do
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(Date.new(2017, 1, 1))
      end

      it "returns expected period" do
        [
          [Date.new(2018, 1, 1), Date.new(2018, 2, 1)],
          [Date.new(2018, 1, 31), Date.new(2018, 2, 28)],
        ].each do |expired_date, expected_next_end_date|
          subscription = FactoryBot.create(:subscription, expired_date: expired_date, recurring_day: expired_date.day)

          expect(subscription.next_period).to eq(expired_date..expected_next_end_date)
        end
      end
    end
  end
end
