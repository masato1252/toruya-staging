# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::Broadcast, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer).customer }
  let(:broadcast) { FactoryBot.create(:broadcast, user: receiver.user) }
  let(:args) do
    {
      receiver: receiver,
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line with social_message had broadcast id" do
      expect(LineClient).to receive(:send).with(receiver.social_customer, broadcast.content)

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: broadcast.content,
          broadcast: broadcast
        ).count
      }.by(1)
    end

    context "when broadcast is reservation_customers" do
      let(:reservation_customer) { FactoryBot.create(:reservation_customer, customer: receiver) }
      let(:broadcast) do
        FactoryBot.create(:broadcast, user: receiver.user, query_type: "reservation_customers", query: {
          filters: [
            {
              field: "reservation_id",
              value: reservation_customer.reservation_id,
              condition: "eq"
            }
          ],
          operator: "or"
        })
      end
      before { receiver.update_columns(reminder_permission: false) }

      it "sends line with social_message had broadcast id even the receiver has not enabled reminder permission" do
        expect(LineClient).to receive(:send).with(receiver.social_customer, broadcast.content)

        expect {
          outcome
        }.to change {
          SocialMessage.where(
            social_customer: receiver.social_customer,
            raw_content: broadcast.content,
            broadcast: broadcast
          ).count
        }.by(1)
      end
    end
  end
end
