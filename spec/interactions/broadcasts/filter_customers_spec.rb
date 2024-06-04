# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::FilterCustomers do
  let(:user) { broadcast.user }
  let(:broadcast) { FactoryBot.create(:broadcast, query: query) }
  let(:args) do
    {
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "no conditions" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user) }
      let(:query) do
        {}
      end

      it "returns expected customers, all customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
      end

      context "when customer in blacklist" do
        let!(:blacklist_customer) { FactoryBot.create(:customer, user: user) }

        before do
          # stub_const("Customer::BLACKLIST_IDS", [ blacklist_customer.id ])
        end

        it "returns expected customers, exclude blacklist_customers" do
          result = outcome.result

          expect(result).to include(matched_customer)
        end
      end
    end

    context "A or B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [1]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [3]) }
      let!(:unmatched_customer2) { FactoryBot.create(:customer, user: user, menu_ids: [1], updated_at: Time.current.advance(years: -1, days: -1)) }

      let(:query) do
        {
          operator: "or",
          filters: [
            {
              field: "menu_ids",
              condition: "contains",
              value: 1
            },
            {
              field: "menu_ids",
              condition: "contains",
              value: 2
            }
          ]
        }
      end

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
        expect(result).not_to include(unmatched_customer2)
      end
    end

    context "A & B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [1, 2]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [3]) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "menu_ids",
              condition: "contains",
              value: 1
            },
            {
              field: "menu_ids",
              condition: "contains",
              value: 2
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

    context "A  & not B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [1, 2]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [1, 3]) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "menu_ids",
              condition: "contains",
              value: 1
            },
            {
              field: "menu_ids",
              condition: "not_contains",
              value: 3
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

    context "not A & not B" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [1]) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, menu_ids: [2, 3]) }

      let(:query) do
        {
          operator: "and",
          filters: [
            {
              field: "menu_ids",
              condition: "not_contains",
              value: 2
            },
            {
              field: "menu_ids",
              condition: "not_contains",
              value: 3
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
