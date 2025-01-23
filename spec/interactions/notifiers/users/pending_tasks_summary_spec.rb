# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::PendingTasksSummary, :with_line do
  let(:receiver) { FactoryBot.create(:social_account).user }
  let(:shop) { FactoryBot.create(:shop, user: receiver) }
  let(:period) { 1.month.ago..Time.current.tomorrow }
  let(:args) do
    {
      receiver: receiver,
      start_at: period.first.to_s,
      end_at: period.last.to_s
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    FactoryBot.create(:social_user, user: receiver)
    FactoryBot.create(:profile, user: receiver)
  end

  describe "#execute" do
    before do
      receiver.subscription.update(plan: Plan.premium_level.take, expired_date: Subscription.today.advance(days: 1))
    end

    it "sends line" do
      FactoryBot.create(:reservation, shop: shop, customers: [FactoryBot.create(:customer, user: receiver)])
      FactoryBot.create_list(:social_message, 4, social_account: receiver.social_account)
      FactoryBot.create_list(:online_service_customer_relation, 3, online_service: FactoryBot.create(:online_service, user: receiver))

      expect {
        outcome
      }.to change {
        SocialUserMessage.where(
          social_user: receiver.social_user,
        ).count
      }.by(1)
      message = SocialUserMessage.last

      expect(message.raw_content).to match(/1/)
      expect(message.raw_content).to match(/4/)
      expect(message.raw_content).to match(/3/)
    end

    context "when there is no pending tasks to notify" do
      it "doesn't send line" do
        expect(LineClient).not_to receive(:send)

        expect {
          outcome
        }.not_to change {
          SocialUserMessage.where(
            social_user: receiver.social_user,
          ).count
        }
      end

      context 'when online_service_customer_relation payment was pending but permission was active(from bundler)' do
        it "doesn't send line" do
          FactoryBot.create_list(:online_service_customer_relation, 3, online_service: FactoryBot.create(:online_service, user: receiver), permission_state: :active, payment_state: :pending)

          expect(LineClient).not_to receive(:send)

          expect {
            outcome
          }.not_to change {
            SocialUserMessage.where(
              social_user: receiver.social_user,
            ).count
          }
        end
      end
    end
  end
end
