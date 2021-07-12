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
end
