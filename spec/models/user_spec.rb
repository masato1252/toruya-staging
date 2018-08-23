require "rails_helper"

RSpec.describe User do

  describe "#member_level" do
    context "when member subscription is free level" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      context "when member sign up in 3 months" do
        it "returns trial" do
          expect(subscription.user.member_level).to eq("trial")
        end
      end

      context "when member sign up over 3 months" do
        before { subscription.user.update_columns(created_at: Time.zone.now.advance(months: -3, seconds: -1)) }

        it "returns free" do
          expect(subscription.user.member_level).to eq("free")
        end
      end
    end

    context "when member subscription is basic level" do
      let(:subscription) { FactoryBot.create(:subscription, :basic) }

      it "returns basic" do
        expect(subscription.user.member_level).to eq("basic")
      end
    end

    context "when member subscription is premium level" do
      let(:subscription) { FactoryBot.create(:subscription, :premium) }

      it "returns premium" do
        expect(subscription.user.member_level).to eq("premium")
      end
    end
  end
end
