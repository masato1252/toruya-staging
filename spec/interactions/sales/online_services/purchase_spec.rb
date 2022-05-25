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
        allow(LineClient).to receive(:flex)

        expect {
          outcome
        }.to change {
          customer.reload.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_free_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id])

        expect(user.reload.customer_latest_activity_at).to be_present
        expect(LineClient).to have_received(:flex)
      end
    end

    context "when sale page was paid version" do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :one_time_payment) }

      it "create a paid relation" do
        allow(LineClient).to receive(:flex)

        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_paid_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id])

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

          it "doesn't touch customer" do
            expect(LineClient).not_to receive(:flex)

            expect {
              outcome
            }.not_to change {
              customer.updated_at
            }
          end
        end

        context 'when customer does NOT purchase yet' do
          let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :canceled, customer: customer) }

          it "create a free relation" do
            allow(LineClient).to receive(:flex)

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
  end
end
