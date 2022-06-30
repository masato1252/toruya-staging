# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::ApproveBundledService, :with_line do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_service) }
  let(:bundler_service) { FactoryBot.create(:online_service, :bundler, user: user) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
  let(:user) { customer.user }
  let(:args) do
    {
      bundled_service: bundled_service,
      bundler_relation: bundler_relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context 'when approve for a bundled service' do
      context 'when bundled_service is forever' do
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: nil) }

        it "creates a bundled relation" do
          expect {
            outcome
          }.to change {
            OnlineServiceCustomerRelation.count
          }.by(1)

          bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
          expect(bundled_relation.expire_at).to be_nil
          expect(bundled_relation).to be_purchased_from_bundler
          expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
          expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
          expect(bundled_relation.bundled_service).to eq(bundled_service)
        end
      end

      context 'when bundled_service is subscription' do
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true) }

        it "creates a bundled relation" do
          expect {
            outcome
          }.to change {
            OnlineServiceCustomerRelation.count
          }.by(1)

          bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
          expect(bundled_relation.expire_at).to be_nil
          expect(bundled_relation).to be_purchased_from_bundler
          expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
          expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
          expect(bundled_relation.bundled_service).to eq(bundled_service)
        end
      end

      context 'when bundled_service got end time' do
        let(:now) { Time.current.round }
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: now.advance(days: 1)) }

        it "creates a bundled relation" do
          Timecop.freeze(Time.current.round) do
            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.count
            }.by(1)

            bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(bundled_relation.expire_at).to eq(now.advance(days: 1))
            expect(bundled_relation).to be_purchased_from_bundler
            expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            expect(bundled_relation.bundled_service).to eq(bundled_service)
          end
        end
      end
    end

    context "when bundled online service was existing purchased online service" do
      context "when existing_relation had end time" do
        let(:existing_relation_expire_at) { Time.current.advance(days: 2).round }
        let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }

        # Customer existing service had end time => bundler service end time => pick better one
        context "when bundled service had better end time" do
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: existing_relation_expire_at.advance(days: 1)) }

          it "use bundler service expire time" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to eq(existing_relation_expire_at.advance(days: 1))
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            end
          end
        end

        # Customer existing service had end time => bundler service end time => pick better one
        context "when bundled service had worse end time" do
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: existing_relation_expire_at.advance(days: -1)) }

          it "use existing online_service expire time" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            end
          end
        end

        # Customer existing service had end time => bundler service recurring => replace the original one(warn customer)
        context "when bundled service was forever" do
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: nil) }

          it "use bundler service forever expire_at" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to be_nil
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            end
          end
        end
      end

      # recurring/forever
      context "when existing_relation had no end time" do
        let(:existing_relation_expire_at) { nil }

        # Customer existing service forever => bundler service end time => pick better one, still forever
        context "when existing_relation is really available forever" do
          let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
          let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
          let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
          let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }

          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.advance(days: 3)) }

          it "use existing online_service forever expire time and give bonus" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            end
          end
        end

        # Customer existing service recurring(membership) => bundler service end time(end_on_months) => still recurring, use bundler service end of month to give free bonus
        context "when existing_relation is recurring subscription" do
          let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
          let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
          let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
          let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, expire_at: nil) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_months: 3, online_service: existing_relation.online_service) }

          it 'is still recurring and give free bonus' do
            expect(Stripe::Coupon).to receive(:create).and_call_original
            expect(StripeSubscriptions::ApplySubscriptionCoupon).to receive(:run).and_call_original

            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to be_nil
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            end
          end
        end

        # Customer purchased service recurring => recurring => use bundler, cancel another one(warn customer)
        context "when bundled service had NO end time" do
          let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
          let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
          let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
          let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, online_service: bundled_service.online_service, customer: customer, expire_at: nil) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: nil) }

          it "use existing online_service forever expire time and cancel the original service subscription" do
            old_stripe_subscription_id = existing_relation.stripe_subscription_id

            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.not_to change {
                OnlineServiceCustomerRelation.count
              }

              expect(outcome.result.expire_at).to eq(existing_relation_expire_at)

              bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
              expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
              expect(existing_relation.reload.stripe_subscription_id).to be_nil
            end
          end
        end
      end
    end
  end
end
