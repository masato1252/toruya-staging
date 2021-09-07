# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Reapply do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :canceled) }
  let(:args) do
    {
      online_service_customer_relation: relation,
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
    end
  end
end
