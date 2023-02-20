# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::QueryActiveServiceCustomers do
  let(:online_service1) { FactoryBot.create(:online_service, user: user) }
  let(:online_service2) { FactoryBot.create(:online_service, user: user) }
  let(:online_service3) { FactoryBot.create(:online_service, user: user) }
  let(:user) { FactoryBot.create(:user) }
  let(:args) do
    {
      user: user,
      query: query
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "A or B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service3.id]) }
      let!(:unmatched_customer2) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id], updated_at: Time.current.advance(years: -1, days: -1)) }
      let!(:online_service_customer_relation1) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service1) }
      let!(:online_service_customer_relation2) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service2) }
      let!(:online_service_customer_relation3) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer2, online_service: online_service1) }

      let(:query) do
        {
          operator: "or",
          filters: [
            {
              field: "online_service_ids",
              condition: "contains",
              value: online_service1.id
            },
            {
              field: "online_service_ids",
              condition: "contains",
              value: online_service2.id
            }
          ]
        }.with_indifferent_access
      end

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
        expect(result).not_to include(unmatched_customer2)
      end
    end

    context "A & B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id, online_service2.id]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service3.id]) }
      let!(:online_service_customer_relation1) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service1) }
      let!(:online_service_customer_relation2) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service2) }
      let!(:online_service_customer_relation3) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service3) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "online_service_ids",
              condition: "contains",
              value: online_service1.id
            },
            {
              field: "online_service_ids",
              condition: "contains",
              value: online_service2.id
            }
          ]
        }
      end

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    context "A & not B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id, online_service2.id]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id, online_service3.id]) }
      let!(:online_service_customer_relation1) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service1) }
      let!(:online_service_customer_relation2) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service2) }
      let!(:online_service_customer_relation3) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service1) }
      let!(:online_service_customer_relation4) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service3) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "online_service_ids",
              condition: "contains",
              value: online_service1.id
            },
            {
              field: "online_service_ids",
              condition: "not_contains",
              value: online_service3.id
            }
          ]
        }
      end

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    # DO NOT SUPPORT YET
    xcontext "not A & not B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service1.id]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, online_service_ids: [online_service2.id, online_service3.id]) }
      let!(:online_service_customer_relation1) { FactoryBot.create(:online_service_customer_relation, :free, customer: matched_customer, online_service: online_service1) }
      let!(:online_service_customer_relation2) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service2) }
      let!(:online_service_customer_relation3) { FactoryBot.create(:online_service_customer_relation, :free, customer: unmatched_customer, online_service: online_service3) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "online_service_ids",
              condition: "not_contains",
              value: online_service2.id
            },
            {
              field: "online_service_ids",
              condition: "not_contains",
              value: online_service3.id
            }
          ]
        }
      end

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end
  end
end
