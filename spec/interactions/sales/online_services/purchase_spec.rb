# frozen_string_literal: true

require "rails_helper"
require "line_client"

RSpec.describe Sales::OnlineServices::Purchase, :with_line do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:sale_page) { FactoryBot.create(:sale_page, :online_service, user: user) }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:payment_type) { SalePage::PAYMENTS[:one_time] }
  let(:args) do
    {
      sale_page: sale_page,
      customer: customer,
      authorize_token: authorize_token,
      payment_type: payment_type
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when sale page was free" do
      let(:payment_type) { SalePage::PAYMENTS[:free] }

      it "create a free relation" do
        expect {
          outcome
        }.to change {
          customer.reload.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_free_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id.to_s])

        expect(user.reload.customer_latest_activity_at).to be_present
        expect(LineClient).to have_received(:flex)
      end
    end

    context "when sale page was paid version" do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :one_time_payment) }

      before do
        # Mock successful PaymentIntent creation for paid purchases
        successful_payment_intent = double(
          id: "pi_test_123",
          status: "succeeded",
          as_json: {
            "id" => "pi_test_123",
            "status" => "succeeded",
            "amount" => sale_page.selling_price_amount.fractional,
            "currency" => sale_page.selling_price_amount.currency.iso_code
          }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

        # Mock payment method retrieval for purchase processing
        allow_any_instance_of(CustomerPayments::PurchaseOnlineService).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "create a paid relation" do
        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_paid_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id.to_s])

        expect(LineClient).to have_received(:flex)
      end

      context "when authorize_token is blank" do
        let(:authorize_token) { nil }

        it "is invalid" do
          expect(LineClient).not_to receive(:flex)

          expect(outcome).to be_invalid
        end
      end
    end

    context "when sale page's product was external online service" do
      let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: FactoryBot.create(:online_service, :external, user: user), user: user) }

      it "create a pending relation" do
        expect(LineClient).not_to receive(:flex)

        expect {
          outcome
        }.not_to change {
          customer.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_pending_payment_state
        expect(relation).to be_pending
        expect(relation.expire_at).to be_nil
        expect(customer.reload.online_service_ids).to be_empty

        expect(user.reload.customer_latest_activity_at).to be_present
      end
    end

    context "when customers already registered this online service" do
      let(:payment_type) { SalePage::PAYMENTS[:free] }
      let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :free, customer: customer) }
      let(:sale_page) { online_service_customer_relation.sale_page }
      let(:customer) { FactoryBot.create(:social_customer, user: user).customer }

      it "doesn't touch customer" do
        expect(LineClient).not_to receive(:flex)

        expect {
          outcome
        }.not_to change {
          customer.updated_at
        }
      end

      context "when customer current state is inactive" do
        context 'when customer already purchased this online service' do
          let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, payment_state: :paid, customer: customer, expire_at: 1.day.ago) }

          it "purchases again" do
            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.where(
                online_service: online_service_customer_relation.online_service,
                customer: online_service_customer_relation.customer,
                sale_page: online_service_customer_relation.sale_page,
              ).count
            }.by(1)

            expect(online_service_customer_relation.reload.current).to be_nil
            expect(OnlineServiceCustomerRelation.last.current).to eq(true)
            expect(LineClient).to have_received(:flex)
          end
        end

        context 'when customer does NOT purchase yet' do
          let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :canceled, :expired, customer: customer) }

          it "create a free relation" do
            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.where(
                online_service: online_service_customer_relation.online_service,
                customer: online_service_customer_relation.customer,
                sale_page: online_service_customer_relation.sale_page
              ).count
            }.by(1)

            expect(LineClient).to have_received(:flex)
          end
        end
      end
    end

    context "when sale page has function_access_id" do
      let(:function_access) { FactoryBot.create(:function_access) }
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :one_time_payment, user: user) }

      before do
        # Mock successful PaymentIntent creation for function access purchases
        successful_payment_intent = double(
          id: "pi_test_123",
          status: "succeeded",
          as_json: {
            "id" => "pi_test_123",
            "status" => "succeeded",
            "amount" => sale_page.selling_price_amount.fractional,
            "currency" => sale_page.selling_price_amount.currency.iso_code
          }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

        # Mock payment method retrieval for purchase processing
        allow_any_instance_of(CustomerPayments::PurchaseOnlineService).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "creates relation with function_access" do
        args[:function_access_id] = function_access.id

        expect {
          outcome
        }.to change {
          customer.reload.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation.function_access_id).to eq(function_access.id)
        expect(relation).to be_active
        expect(LineClient).to have_received(:flex)
      end
    end
  end
end
