# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelations::ChangeCreditCardAbility do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context 'when service is external' do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, online_service: FactoryBot.create(:online_service, :external)) }

      it 'returns false' do
        expect(outcome.result).to eq(false)
      end
    end

    context 'when service is recurring_charge_required' do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }

      it 'returns true' do
        allow(relation).to receive(:payment_legal_to_access?).and_return(true)

        expect(outcome.result).to eq(true)
      end
    end

    context "when payments was completed" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer) }

      it 'returns false' do
        FactoryBot.create(:customer_payment, :completed, product: relation)

        expect(outcome.result).to eq(false)
      end
    end

    context 'when service multiple times payment' do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :multiple_times_payment) }

      context "when all payments is successful" do
        it 'returns true' do
          first_order_id = relation.price_details.first.order_id
          FactoryBot.create(:customer_payment, :completed, product: relation, order_id: first_order_id)

          expect(outcome.result).to eq(true)
        end
      end

      context "when some payments is failed" do
        it 'returns false' do
          first_order_id = relation.price_details.first.order_id
          FactoryBot.create(:customer_payment, :processor_failed, product: relation, order_id: first_order_id)

          expect(outcome.result).to eq(false)
        end
      end
    end
  end
end
