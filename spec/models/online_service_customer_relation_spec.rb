# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelation do
  describe "#state" do
    context "when service was started and doesn't end" do
      [
        { payment_state: :pending, permission_state: :pending, state: "pending" },
        { payment_state: :free, permission_state: :pending, state: "pending" },
        { payment_state: :failed, permission_state: :pending, state: "inactive" },
        { payment_state: :refunded, permission_state: :pending, state: "inactive" },
        { payment_state: :canceled, permission_state: :pending, state: "inactive" },
        { payment_state: :partial_paid, permission_state: :pending, state: "pending" },
        { payment_state: :paid, permission_state: :pending, state: "pending" },

        { payment_state: :pending, permission_state: :active, state: "accessible" },
        { payment_state: :free, permission_state: :active, state: "accessible" },
        { payment_state: :partial_paid, permission_state: :active, state: "accessible" },
        { payment_state: :paid, permission_state: :active, state: "accessible" }
      ].each do |states|
        it "permission_state: #{states[:permission_state]}, payment_state: #{states[:payment_state]}  expects state is #{states[:state]}" do
          relation = FactoryBot.build(
            :online_service_customer_relation,
            permission_state: states[:permission_state],
            payment_state: states[:payment_state]
          )

          expect(relation.state).to eq(states[:state])
        end
      end
    end

    context "when service was expired" do
      [
        { payment_state: :pending, permission_state: :pending, state: "inactive" },
        { payment_state: :free, permission_state: :pending, state: "inactive" },
        { payment_state: :failed, permission_state: :pending, state: "inactive" },
        { payment_state: :refunded, permission_state: :pending, state: "inactive" },
        { payment_state: :canceled, permission_state: :pending, state: "inactive" },
        { payment_state: :partial_paid, permission_state: :pending, state: "inactive" },
        { payment_state: :paid, permission_state: :pending, state: "inactive" },

        { payment_state: :pending, permission_state: :active, state: "inactive" },
        { payment_state: :free, permission_state: :active, state: "inactive" },
        { payment_state: :partial_paid, permission_state: :active, state: "inactive" },
        { payment_state: :paid, permission_state: :active, state: "inactive" }
      ].each do |states|
        it "permission_state: #{states[:permission_state]}, payment_state: #{states[:payment_state]}  expects state is #{states[:state]}" do
          relation = FactoryBot.build(
            :online_service_customer_relation, :expired,
            permission_state: states[:permission_state],
            payment_state: states[:payment_state]
          )

          expect(relation.state).to eq(states[:state])
        end
      end
    end

    context "when service does not start yet but customer legal to use" do
      let(:service_start_yet) { FactoryBot.build(:online_service, start_at: Time.now.tomorrow) }

      [
        { payment_state: :pending, permission_state: :pending, state: "pending" },
        { payment_state: :free, permission_state: :pending, state: "pending" },
        { payment_state: :failed, permission_state: :pending, state: "inactive" },
        { payment_state: :refunded, permission_state: :pending, state: "inactive" },
        { payment_state: :canceled, permission_state: :pending, state: "inactive" },
        { payment_state: :partial_paid, permission_state: :pending, state: "pending" },
        { payment_state: :paid, permission_state: :pending, state: "pending" },

        { payment_state: :pending, permission_state: :active, state: "available" },
        { payment_state: :free, permission_state: :active, state: "available" },
        { payment_state: :partial_paid, permission_state: :active, state: "available" },
        { payment_state: :paid, permission_state: :active, state: "available" }
      ].each do |states|
        it "permission_state: #{states[:permission_state]}, payment_state: #{states[:payment_state]}  expects state is #{states[:state]}" do
          relation = FactoryBot.build(
            :online_service_customer_relation,
            permission_state: states[:permission_state],
            payment_state: states[:payment_state],
            online_service: service_start_yet
          )

          expect(relation.state).to eq(states[:state])
        end
      end
    end
  end
end
