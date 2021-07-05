# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Approve do
  let(:relation) { FactoryBot.create(:online_service_customer_relation) }
  let(:customer) { relation.customer }
  let(:online_service) { relation.online_service  }
  let(:args) do
    {
      relation: relation,
      customer: customer,
      online_service: online_service
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when relation is pending" do
      it "updates relation states" do
        expect {
          outcome
        }.to change {
          customer.updated_at
        }

        expect(relation).to be_paid_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(online_service.current_expire_time)
        expect(customer.reload.online_service_ids).to eq([online_service.id])
      end
    end

    context "when relation is purchased" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }

      it "does nothing" do
        expect {
          outcome
        }.not_to change {
          customer.updated_at
        }
      end
    end
  end
end
