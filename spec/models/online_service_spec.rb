# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }
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
      before { Timecop.freeze(3.days.ago.round) }

      context "when online_service service was a paid required service" do
        let!(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :paid, online_service: online_service) }

        it "returns relation paid time" do
          expect(online_service.start_at_for_customer(customer).round).to eq(online_service_customer_relation.paid_at.round)
        end
      end

      context "when online_service service was a free service" do
        let!(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :free, online_service: online_service) }

        it "returns relation created time" do
          expect(online_service.start_at_for_customer(customer).round).to eq(online_service_customer_relation.created_at.round)
        end
      end
    end
  end

  describe "#recurring_charge_required?" do
    context 'when service is bundler' do
      let(:bundler_service) { FactoryBot.create(:online_service, :bundler) }

      context 'when all services got end time' do
        it 'is false' do
          bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
          bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_days: 3)

          expect(bundler_service.recurring_charge_required?).to eq(false)
        end
      end

      context 'when one of services is forever' do
        context 'when the forever service is membership' do
          it 'is true' do
            user = FactoryBot.create(:access_provider, :stripe).user
            membership = FactoryBot.create(:online_service, :membership, user: user)
            bundled_service_with_membership = FactoryBot.create(:bundled_service, bundler_service: bundler_service, online_service: membership)
            bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_days: 3)

            expect(bundler_service.recurring_charge_required?).to eq(true)
          end
        end

        context 'when the forever service is not membership' do
          it 'is true' do
            bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)
            bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_days: 3)

            expect(bundler_service.recurring_charge_required?).to eq(false)
          end
        end
      end
    end
  end
end
