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
      let(:relation_mock) { double("relation", legal_to_access?: false, inactive?: false) }
      let(:approve_outcome) { double("approve_outcome", valid?: true, invalid?: false) }

      before do
        # Mock both services to avoid complex setup
        allow(Sales::OnlineServices::PurchaseBundlerService).to receive(:run).and_return(relation_mock)
        allow(Sales::OnlineServices::PurchaseNormalService).to receive(:run).and_return(relation_mock)
        allow(CustomerPayments::ApproveManually).to receive(:run).and_return(approve_outcome)
      end

      context "when online_service is a bundler" do
        let(:online_service) { double("bundler_service", bundler?: true) }

        it "calls PurchaseBundlerService" do
          expect(Sales::OnlineServices::PurchaseBundlerService).to receive(:run).with(
            online_service: online_service,
            customer: customer,
            payment_type: SalePage::PAYMENTS[:assignment]
          )
          expect(Sales::OnlineServices::PurchaseNormalService).not_to receive(:run)

          described_class.run(customer: customer, online_service: online_service)
        end
      end

      context "when online_service is not a bundler" do
        let(:online_service) { double("normal_service", bundler?: false) }

        it "calls PurchaseNormalService" do
          expect(Sales::OnlineServices::PurchaseNormalService).to receive(:run).with(
            online_service: online_service,
            customer: customer,
            payment_type: SalePage::PAYMENTS[:assignment]
          )
          expect(Sales::OnlineServices::PurchaseBundlerService).not_to receive(:run)

          described_class.run(customer: customer, online_service: online_service)
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

      context "when online_service is a bundler" do
        let(:online_service) { FactoryBot.create(:online_service, :bundler, user: user) }

        it "verifies that online_service.bundler? returns true" do
          expect(online_service.bundler?).to be true
        end
      end
    end
  end
end
