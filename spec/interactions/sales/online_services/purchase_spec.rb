# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Purchase do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:sale_page) { FactoryBot.create(:sale_page, :online_service, user: user) }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      sale_page: sale_page,
      customer: customer,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when sale page was free" do
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
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id])
      end
    end

    context "when sale page was paid version" do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :paid_version) }
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
        expect(customer.reload.online_service_ids).to eq([sale_page.product_id])
      end
    end

    context "when sale page's product was online service" do
      let(:sale_page) { FactoryBot.create(:sale_page, product: FactoryBot.create(:online_service, :external, user: user)) }
      it "create a pending relation" do
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
      end
    end

    context "when customers already registered this online service" do
      let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :free) }
      let(:sale_page) { online_service_customer_relation.sale_page }
      let(:customer) { online_service_customer_relation.customer }

      it "doesn't touch customer" do
        expect {
          outcome
        }.not_to change {
          customer.updated_at
        }
      end
    end
  end
end
