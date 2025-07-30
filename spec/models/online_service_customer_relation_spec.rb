# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelation do
  describe "#order_completed" do
    let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :multiple_times_payment) }

    it 'returns order id with completed status' do
      expect(online_service_customer_relation.order_completed).to be_blank

      first_order_id = online_service_customer_relation.price_details.first.order_id
      FactoryBot.create(:customer_payment, :completed, product: online_service_customer_relation, order_id: first_order_id)
      expect(OnlineServiceCustomerRelation.find(online_service_customer_relation.id).order_completed).to eq({ first_order_id => true })

      second_order_id = online_service_customer_relation.price_details.second.order_id
      FactoryBot.create(:customer_payment, :processor_failed, product: online_service_customer_relation, order_id: second_order_id)
      expect(OnlineServiceCustomerRelation.find(online_service_customer_relation.id).order_completed).to eq({ first_order_id => true, second_order_id => false })

      FactoryBot.create(:customer_payment, :completed, product: online_service_customer_relation, order_id: second_order_id)
      expect(OnlineServiceCustomerRelation.find(online_service_customer_relation.id).order_completed).to eq({ first_order_id => true, second_order_id => true })
    end
  end

  describe "#state" do
    context "when service was started and doesn't end" do
      [
        { payment_state: :pending, permission_state: :pending, state: "pending" },
        { payment_state: :free, permission_state: :pending, state: "pending" },
        { payment_state: :failed, permission_state: :pending, state: "inactive" },
        { payment_state: :refunded, permission_state: :pending, state: "inactive" },
        { payment_state: :canceled, permission_state: :pending, state: "pending" },
        { payment_state: :canceled, permission_state: :active, state: "accessible" },
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
        { payment_state: :canceled, permission_state: :active, state: "inactive" },
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
        { payment_state: :canceled, permission_state: :pending, state: "pending" },
        { payment_state: :canceled, permission_state: :active, state: "available" },
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

  describe 'with bundler_relation' do
    let(:user) { FactoryBot.create(:user) }
    let(:customer) { FactoryBot.create(:customer, user: user) }
    let(:bundler_service) { FactoryBot.create(:online_service, :bundler, user: user) }
    let(:bundler_sale_page) { FactoryBot.create(:sale_page, :online_service, product: bundler_service, user: user) }
    let(:sale_page) { FactoryBot.create(:sale_page, :online_service, product: bundler_service, user: user) }

    let!(:bundler_relation) do
      FactoryBot.create(:online_service_customer_relation,
        customer: customer,
        sale_page: bundler_sale_page,
        online_service: bundler_service,
        payment_state: :paid,
        permission_state: :active
      )
    end

    let(:relation) do
      FactoryBot.create(:online_service_customer_relation,
        customer: customer,
        sale_page: sale_page,
        online_service: bundler_service,
        payment_state: :failed,
        permission_state: :pending
      )
    end

    it 'state fallback to bundler_relation when sale_page exists' do
      expect(relation.state).to eq(bundler_relation.state)
      expect(relation.legal_to_access?).to eq(bundler_relation.legal_to_access?)
      expect(relation.payment_legal_to_access?).to eq(bundler_relation.payment_legal_to_access?)
      expect(relation.service_started?).to eq(bundler_relation.service_started?)
      expect(relation.purchased?).to eq(bundler_relation.purchased?)
      expect(relation.forever?).to eq(bundler_relation.forever?)
    end

    it 'returns inactive if both are inactive' do
      bundler_relation.update!(payment_state: :failed, permission_state: :pending)
      expect(relation.state).to eq('inactive')
      expect(relation.legal_to_access?).to eq(false)
    end

    it 'returns accessible if bundler_relation is accessible' do
      expect(relation.state).to eq('accessible')
      expect(relation.legal_to_access?).to eq(true)
    end

    it 'returns nil bundler_relation when sale_page is nil' do
      relation.update!(sale_page: nil)
      expect(relation.bundler_relation).to be_nil
    end

    it 'returns nil bundler_relation when no matching relation found' do
      other_sale_page = FactoryBot.create(:sale_page, :online_service, user: user)
      relation.update!(sale_page: other_sale_page)
      expect(relation.bundler_relation).to be_nil
    end
  end
end
