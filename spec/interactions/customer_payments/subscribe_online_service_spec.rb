# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::SubscribeOnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }
  let(:args) do
    {
      online_service_customer_relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  context "when subscribes successfully" do
    it "changes to expected state" do
      outcome

      expect(relation).to be_paid_payment_state
      expect(relation).to be_active
    end
  end

  context "when subscribes failed" do
    it "changes to expected state" do
      allow(OnlineServiceCustomerRelations::Subscribe).to receive(:run).and_return(double(valid?: false, errors: spy))

      outcome

      expect(relation).to be_failed_payment_state
      expect(relation).to be_pending
    end
  end
end
