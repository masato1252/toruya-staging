require "rails_helper"
require "pending_reservations_summary_job"

RSpec.describe "rake subscriptions:charge" do
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(today)
  end

  let!(:subscription) { FactoryBot.create(:subscription, :basic, expired_date: expired_date, recurring_day: recurring_day) }

  context "when today is before subscription's expired date" do
    let(:expired_date) { Date.new(2018, 2, 28) }
    let(:recurring_day) { 31 }
    let(:today) { Date.new(2018, 1, 31) }

    it "does nothing" do
      expect(SubscriptionChargeJob).not_to receive(:perform_later)

      task.execute
    end
  end

  context "when today is equal or over subscription's expired date" do
    let(:expired_date) { Date.new(2018, 1, 31) }
    let(:today) { Date.new(2018, 1, 31) }
    let(:recurring_day) { 31 }

    context "when today is the recurring day" do
      it "charges user" do
        expect(SubscriptionChargeJob).to receive(:perform_later).with(subscription)

        task.execute
      end

      context "when user subscribe free plan" do
        let!(:subscription) { FactoryBot.create(:subscription, :free, expired_date: expired_date, recurring_day: recurring_day) }

        it "does nothing" do
          expect(SubscriptionChargeJob).not_to receive(:perform_later)

          task.execute
        end
      end
    end

    context "when today is not recurring day" do
      let(:expired_date) { Date.new(2018, 1, 31) }
      let(:today) { Date.new(2018, 2, 28) }
      let(:recurring_day) { 31 }

      context "when today is the last day of the month" do
        it "charges user" do
          expect(SubscriptionChargeJob).to receive(:perform_later).with(subscription)

          task.execute
        end
      end

      context "when today is not the last day of the month" do
        let(:today) { Date.new(2018, 2, 27) }

        it "does nothing" do
          expect(SubscriptionChargeJob).not_to receive(:perform_later)

          task.execute
        end
      end
    end
  end
end

RSpec.describe "rake subscriptions:charge_reminder" do
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(today)
  end

  let!(:subscription) { FactoryBot.create(:subscription, :basic, expired_date: expired_date, recurring_day: recurring_day) }

  context "when today is 7 days ago before subscription's expired date" do
    let(:expired_date) { Date.new(2018, 2, 28) }
    let(:recurring_day) { 31 }
    let(:today) { Date.new(2018, 2, 21) }

    it "reminds users" do
      expect(SubscriptionMailer).to receive(:charge_reminder).with(subscription).and_return(double(deliver_later: true))

      task.execute
    end

    context "when user subscribe free plan" do
      let!(:subscription) { FactoryBot.create(:subscription, :free, expired_date: expired_date, recurring_day: recurring_day) }

      it "does nothing" do
        expect(SubscriptionMailer).not_to receive(:charge_reminder)

        task.execute
      end
    end
  end

  context "when today is not equal 7 days ago before subscription's expired date" do
    let(:expired_date) { Date.new(2018, 2, 28) }
    let(:recurring_day) { 31 }

    context "when today 8 days ago before expired date" do
      let(:today) { Date.new(2018, 2, 20) }

      it "does nothing" do
        expect(SubscriptionMailer).not_to receive(:charge_reminder)

        task.execute
      end
    end

    context "when today 6 days ago before expired date" do
      let(:today) { Date.new(2018, 2, 22) }

      it "does nothing" do
        expect(SubscriptionMailer).not_to receive(:charge_reminder)

        task.execute
      end
    end
  end
end
