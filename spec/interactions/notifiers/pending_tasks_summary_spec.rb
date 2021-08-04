# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::PendingTasksSummary do
  let(:receiver) { FactoryBot.create(:social_account).user }
  let(:shop) { FactoryBot.create(:shop, user: receiver) }
  let(:period) { 1.month.ago..Time.current.tomorrow }
  let(:args) do
    {
      receiver: receiver,
      period: period
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    FactoryBot.create(:social_user, user: receiver)
    FactoryBot.create(:profile, user: receiver)
  end

  describe "#execute" do
    it "sends line" do
      allow(LineClient).to receive(:send)
      FactoryBot.create(:reservation, shop: shop, customers: [FactoryBot.create(:customer, user: receiver)])
      FactoryBot.create_list(:social_message, 2, social_account: receiver.social_account)
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
      expect(message.raw_content).to match(/2/)
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
    end
  end
end
