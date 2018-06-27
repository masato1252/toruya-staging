require "rails_helper"

RSpec.describe Subscription do
  let(:subscription) { FactoryBot.create(:subscription) }

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
        let(:charge_date) { Date.new(2018, 1, 31) }

        it "sets the expired date to last charge date's end of next month" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
        end
      end

      context "when the recurring_day is less or equal than the end of month" do
        let(:charge_date) { Date.new(2018, 1, 27) }

        it "sets the expired date to next charge date" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(Date.new(2018, 2, 27))
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
end
