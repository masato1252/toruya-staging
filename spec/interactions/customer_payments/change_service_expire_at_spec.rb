# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::ChangeServiceExpireAt do
  let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, expire_at: 1.day.ago) }
  let(:expire_at) { nil }
  let(:args) do
    {
      online_service_customer_relation: online_service_customer_relation,
      expire_at: expire_at
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "expires relation" do
      expect {
        outcome
      }.to change {
        online_service_customer_relation.expire_at
      }.to(expire_at)
    end

    context "when service is bundler" do
      let(:bundler_service) { FactoryBot.create(:online_service, :bundler) }
      let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, expire_at: 1.day.ago, online_service: bundler_service) }
      let(:customer) { online_service_customer_relation.customer }

      it "expires all relation under bundler service" do
        bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
        relation_with_end_at = FactoryBot.create(:online_service_customer_relation, customer: customer, online_service: bundled_service_with_end_at.online_service, expire_at: Time.current.tomorrow)
        bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_days: 3)
        relation_with_end_of_days = FactoryBot.create(:online_service_customer_relation, customer: customer, online_service: bundled_service_with_end_of_days.online_service, expire_at: Time.current.advance(days: 3))

        outcome

        expect(online_service_customer_relation.reload.expire_at).to eq(expire_at)
        expect(relation_with_end_at.reload.expire_at).to eq(expire_at)
        expect(relation_with_end_of_days.reload.expire_at).to eq(expire_at)
      end
    end
  end
end
