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

    context "when customer purchased this service(bundled service) from a bundler" do
      before { StripeMock.start }
      after { StripeMock.stop }
      let(:user) { FactoryBot.create(:user) }
      let(:customer) { FactoryBot.create(:customer, user: user) }
      let!(:access_provider) { FactoryBot.create(:access_provider, :stripe, user: user) }
      let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, user: user, product: bundler_service) }
      let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, :active, online_service: bundler_service, sale_page: sale_page, customer: customer, expire_at: Time.current.tomorrow) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, permission_state: :active, sale_page: sale_page, online_service: FactoryBot.create(:online_service, user: user), customer: customer) }
      let(:bundler_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: user) }
      let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true, online_service: relation.online_service) }

      context "when this bundler got expire_at" do
        it "change the bundled relation expire_at" do
          expect {
            outcome
          }.to change {
            relation.expire_at
          }

          expect(relation).to be_active
        end
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
