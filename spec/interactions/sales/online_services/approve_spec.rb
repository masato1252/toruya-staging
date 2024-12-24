# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Approve, :with_line do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let(:online_service) { relation.online_service }
  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when relation is assignment" do
      let(:online_service) { FactoryBot.create(:online_service, user: customer.user) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :assignment, customer: customer, online_service: online_service) }

      it "updates relation states" do
        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        expect(relation).to be_active
        expect(relation).to be_pending_payment_state
        expect(relation.expire_at).to eq(online_service.current_expire_time)
        expect(relation.paid_at).to be_present
        expect(customer.reload.online_service_ids).to eq([online_service.id.to_s])
      end
    end
    context "when sale page is free" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :free, customer: customer) }

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
        expect(customer.reload.online_service_ids).to eq([online_service.id.to_s])
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
        expect(customer.reload.online_service_ids).to eq([online_service.id.to_s])
      end

      context "when service is external" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: external_online_service, customer: customer, sale_page: sale_page) }
        let(:external_online_service) { FactoryBot.create(:online_service, :external) }
        let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: external_online_service) }

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
