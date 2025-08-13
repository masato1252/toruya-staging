# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Assign do
  let(:current_time) { Time.current.round }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }

  describe "#execute" do
    describe "service selection logic" do
      context "when online_service is a bundler" do
        let(:online_service) { FactoryBot.create(:online_service, :bundler, user: user) }

        it "creates relationship for bundler service" do
          expect(online_service.bundler?).to be true

          expect {
            described_class.run(customer: customer, online_service: online_service)
          }.to change {
            OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer).count
          }.by(1)

          latest_relation = OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer).last
          expect(latest_relation.online_service).to eq(online_service)
          expect(latest_relation.customer).to eq(customer)
        end
      end

      context "when online_service is not a bundler" do
        let(:online_service) { FactoryBot.create(:online_service, user: user) }

        it "creates relationship for normal service" do
          expect(online_service.bundler?).to be false

          expect {
            described_class.run(customer: customer, online_service: online_service)
          }.to change {
            OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer).count
          }.by(1)

          latest_relation = OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer).last
          expect(latest_relation.online_service).to eq(online_service)
          expect(latest_relation.customer).to eq(customer)
        end
      end
    end

    context "with actual factory objects" do
      let(:args) do
        {
          customer: customer,
          online_service: online_service
        }
      end
      let(:outcome) { described_class.run(args) }

      context "when online_service is not a bundler" do
        let(:online_service) { FactoryBot.create(:online_service, user: user) }

        it "verifies that online_service.bundler? returns false" do
          expect(online_service.bundler?).to be false
        end

        it "creates a new online_service_customer_relation" do
          expect {
            outcome
          }.to change {
            OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer, sale_page: nil).count
          }.by(1)

          latest_relation = OnlineServiceCustomerRelation.where(online_service: online_service, customer: customer, sale_page: nil).last
          expect(latest_relation).to have_attributes(
            current: true,
            payment_state: "manual_paid",
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

      context "when online_service is a bundler" do
        let(:online_service) { FactoryBot.create(:online_service, :bundler, user: user) }

        it "verifies that online_service.bundler? returns true" do
          expect(online_service.bundler?).to be true
        end
      end
    end
  end
end
