# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineService do
  let!(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, online_service: online_service) }
  let(:online_service) { FactoryBot.create(:online_service) }
  let(:customer) { online_service_customer_relation.customer }

  describe "#start_at_for_customer" do
    context "when online_service had start time" do
      let(:start_at) { Time.current }
      let(:online_service) { FactoryBot.create(:online_service, start_at: start_at) }

      it "returns online_service start time" do
        expect(online_service.start_at_for_customer(customer)).to eq(start_at)
      end
    end

    context "when online_service doesn't have start time" do
      context "when online_service service was a paid required service" do
        let!(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :paid, online_service: online_service) }

        it "returns relation paid time" do
          expect(online_service.start_at_for_customer(customer)).to eq(online_service_customer_relation.paid_at)
        end
      end

      context "when online_service service was a free service" do
        let!(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: online_service) }

        it "returns relation created time" do
          expect(online_service.start_at_for_customer(customer)).to eq(online_service_customer_relation.created_at)
        end
      end
    end
  end
end
