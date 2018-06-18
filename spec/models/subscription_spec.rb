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
      let!(:last_completed_charge) { FactoryBot.create(:subscription_charge, :completed, user: subscription.user) }

      context "when the recurring_day is over the end of month" do
        it "sets the last charge date's next day of end of month(first day of next month)" do
          subscription.set_expire_date

          expect(subscription.expired_date).to eq(last_completed_charge.charge_date.next_month.next_day)
        end
      end

      context "when the recurring_day is less or equal than the end of month" do
        it "sets the next day of next charge date" do
        end
      end
    end

    context "when users never paid their subscription" do
      it "sets tomorrow" do
        subscription.set_expire_date

        expect(subscription.expired_date).to eq(described_class.today.next_day)
      end
    end
  end
end
