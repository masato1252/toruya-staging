# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Approve do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment) }
  let(:customer) { relation.customer }
  let(:online_service) { relation.online_service  }
  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when sale page is free" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }

      it "updates relation states" do
        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        expect(relation).to be_active
        expect(relation).to be_free_payment_state
        expect(relation.expire_at).to eq(online_service.current_expire_time)
        expect(relation.paid_at).to be_blank
        expect(customer.reload.online_service_ids).to eq([online_service.id])
      end
    end

    context 'when sale page is not free' do
      it "updates relation states" do
        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        expect(relation).to be_active
        expect(relation.expire_at).to eq(online_service.current_expire_time)
        expect(relation.paid_at).to be_present
        expect(customer.reload.online_service_ids).to eq([online_service.id])
      end

      context "when service is external" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: external_online_service) }
        let(:external_online_service) { FactoryBot.create(:online_service, :external) }

        it "marks payment_state as paid" do
          expect {
            outcome
          }.to change {
            relation.payment_state
          }.to("paid")
        end
      end
    end
  end
end
