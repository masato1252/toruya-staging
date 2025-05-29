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

  describe "#customer_message_in_a_row?" do
    let(:user) { FactoryBot.create(:user) }

    describe "when there are no customer messages" do
      it "returns false" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "when there are insufficient message days" do
      before do
        # Create messages for only 2 days when we need 3 consecutive days
        FactoryBot.create(:social_message, :customer, user: user, created_at: 2.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
      end

      it "returns false" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "when there are messages but not consecutive" do
      before do
        # Create messages with gaps: day 5, day 3, day 1 (not consecutive)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 5.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
      end

      it "returns false when looking for 3 consecutive days" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "when there are exactly m consecutive days with messages" do
      before do
        # Create messages for exactly 3 consecutive days
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 2.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
      end

      it "returns true" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_truthy
      end
    end

    describe "when there are more than m consecutive days with messages" do
      before do
        # Create messages for 5 consecutive days (more than required 3)
        (1..5).each do |i|
          FactoryBot.create(:social_message, :customer, user: user, created_at: i.days.ago)
        end
      end

      it "returns true" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_truthy
      end
    end

    describe "when there are multiple sets of consecutive days" do
      before do
        # Create two separate sets of consecutive days
        # Set 1: 7-6-5 days ago (3 consecutive)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 7.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 6.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 5.days.ago)

        # Gap on day 4

        # Set 2: 3-2-1 days ago (3 consecutive)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 2.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
      end

      it "returns true when any set meets the requirement" do
        expect(user.customer_message_in_a_row?(10, 3)).to be_truthy
      end
    end

    describe "when messages are from different message types" do
      before do
        # Mix of customer and non-customer messages
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago)
        FactoryBot.create(:social_message, :staff, user: user, created_at: 2.days.ago)  # staff message
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
      end

      it "only counts customer messages" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "when messages are outside the time range" do
      before do
        # Create messages older than the specified range
        FactoryBot.create(:social_message, :customer, user: user, created_at: 10.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 9.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 8.days.ago)
      end

      it "returns false when messages are outside the n-day range" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "when there are messages from different users" do
      let(:other_user) { FactoryBot.create(:user) }

      before do
        # Create messages for the target user (only 2 days)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 2.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)

        # Create messages for another user on the missing day
        FactoryBot.create(:social_message, :customer, user: other_user, created_at: 3.days.ago)
      end

      it "only counts messages for the specific user" do
        expect(user.customer_message_in_a_row?(7, 3)).to be_falsey
      end
    end

    describe "edge cases" do
      it "returns false when m is greater than n" do
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
        expect(user.customer_message_in_a_row?(3, 5)).to be_falsey
      end

      it "handles the case when m equals 1" do
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)
        expect(user.customer_message_in_a_row?(7, 1)).to be_truthy
      end

      it "handles multiple messages on the same day" do
        # Multiple messages on the same day should still count as one day
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 3.days.ago + 1.hour)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 2.days.ago)
        FactoryBot.create(:social_message, :customer, user: user, created_at: 1.day.ago)

        expect(user.customer_message_in_a_row?(7, 3)).to be_truthy
      end
    end
  end
end
