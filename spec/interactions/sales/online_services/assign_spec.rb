# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Assign do
  let(:current_time) { Time.current.round }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:online_service) { FactoryBot.create(:online_service, user: user) }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }
  let(:args) do
    {
      customer: customer,
      online_service: online_service
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a new online_service_customer_relation" do
      expect {
        outcome
      }.to change {
        OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer, sale_page: nil).count
      }.by(1)

      latest_relation = OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer, sale_page: nil).last
      expect(latest_relation).to have_attributes(
        current: true,
        payment_state: "pending",
        permission_state: "active"
      )
      price_details = latest_relation.price_details.first
      expect(price_details).to have_attributes(
        amount: Money.zero,
        order_id: nil,
        assignment: true
      )

      last_payment = CustomerPayment.where(product: latest_relation).last
      expect(last_payment).to have_attributes(
        amount: Money.zero,
        charge_at: nil, 
        manual: true,
        state: "manually_approved"
      )
    end
  end
end
