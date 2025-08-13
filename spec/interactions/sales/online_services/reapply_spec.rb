# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Reapply do
  let(:user) { FactoryBot.create(:user) }
  let(:online_service) { FactoryBot.create(:online_service, user: user) }
  let(:sale_page) { FactoryBot.create(:sale_page, :online_service, product: online_service, user: user) }
  let(:relation) {
    FactoryBot.create(:online_service_customer_relation,
      online_service: online_service,
      sale_page: sale_page,
      payment_state: :failed,
      permission_state: :pending,
      expire_at: 1.day.ago
    )
  }
  let(:args) do
    {
      online_service_customer_relation: relation,
      payment_type: SalePage::PAYMENTS[:free]
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a new online_service_customer_relation" do
      expect {
        outcome
      }.to change {
        OnlineServiceCustomerRelation.where(online_service: relation.online_service, customer: relation.customer, sale_page: relation.sale_page).count
      }.by(1)

      relation.reload
      latest_relation = OnlineServiceCustomerRelation.where(online_service: relation.online_service, customer: relation.customer, sale_page: relation.sale_page).last
      expect(relation.current).to be_nil
      expect(latest_relation).to have_attributes(
        current: true,
        payment_state: "pending",
        permission_state: "pending"
      )
      price_details = latest_relation.price_details.first
      expect(price_details).to have_attributes(
        amount: Money.zero,
        order_id: nil
      )
    end
  end
end
