# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do

  describe "#permission_level" do
    context "when member subscription is free level" do
      let(:subscription) { FactoryBot.create(:subscription, :free) }

      context "when member was in trial_expired_date" do
        it "returns trial" do
          expect(subscription.user.permission_level).to eq("trial")
        end
      end

      context "when today was over member's trial_expired_date" do
        before do
          subscription.update(trial_expired_date: Date.today.yesterday)
        end

        it "returns free" do
          expect(subscription.user.permission_level).to eq("free")
        end
      end
    end

    context "when member subscription is basic level" do
      let(:subscription) { FactoryBot.create(:subscription, :basic) }

      it "returns basic" do
        expect(subscription.user.permission_level).to eq("basic")
      end
    end

    context "when member subscription is premium level" do
      let(:subscription) { FactoryBot.create(:subscription, :premium) }

      it "returns premium" do
        expect(subscription.user.permission_level).to eq("premium")
      end
    end
  end

  describe "#hi_message" do
    let(:user) { FactoryBot.create(:user) }

    context "when the user has a referral" do
      let(:referee) { FactoryBot.create(:user, referral_token: "ref123") }
      let!(:referral) { FactoryBot.create(:referral, referrer: user, referee: referee) }

      it "returns a message with the referee's referral token" do
        expect(user.hi_message).to eq("👩 New user joined, user_id: #{user.id} from ref123")
      end
    end

    context "when the user does not have a referral" do
      it "returns a message without a referral token" do
        expect(user.hi_message).to eq("👩 New user joined, user_id: #{user.id}")
      end
    end
  end
end
