# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelations::ReconnectBestContract do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, permission_state: :active) }
  let(:customer) { relation.customer }
  let(:online_service) { relation.online_service }

  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when customer doesn't purchase the same service from some other sale page before(no other relations)" do
      it "pends the original relation" do
        outcome

        expect(relation).to be_pending
      end
    end

    context "when customer purchased the same service from some other sale page before(had other relations)" do
      let!(:other_relation) { FactoryBot.create(:online_service_customer_relation, online_service: online_service, customer: customer, current: nil, expire_at: nil, permission_state: :pending) }

      context "when other relation was not expired(expire_at nil is forever)" do
        it "pends the original relation and activates the other one" do
          outcome
          other_relation.reload

          expect(relation).to be_pending
          expect(relation.current).to be_nil
          expect(other_relation).to be_active
          expect(other_relation.current).to eq(true)
        end
      end

      context "when other relation was expired" do
        let!(:other_relation) { FactoryBot.create(:online_service_customer_relation, online_service: online_service, customer: customer, current: nil, expire_at: Time.current.yesterday, permission_state: :pending) }

        it "pends the original relation and doesn't touch the other" do
          outcome
          other_relation.reload

          expect(relation).to be_pending
          expect(relation.current).to eq(true)
          expect(other_relation).to be_pending
          expect(other_relation.current).to be_nil
        end
      end
    end
  end
end
