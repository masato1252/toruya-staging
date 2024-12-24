# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::ApproveBundledService, :with_line do
  before { StripeMock.start }
  after { StripeMock.stop }
  let!(:access_provider) { FactoryBot.create(:access_provider, :stripe, user: user) }
  let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_service) }
  let(:bundler_service) { FactoryBot.create(:online_service, :bundler, user: user) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
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
      context 'when bundled_service got end time' do
        let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
        let(:now) { Time.current.round }
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: now.advance(days: 1)) }

        it "creates a bundled relation with end time" do
          Timecop.freeze(Time.current.round) do
            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
            }.by(1)

            bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(bundled_relation.expire_at).to eq(now.advance(days: 1))
            expect(bundled_relation).to be_purchased_from_bundler
            expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "assignment"=> false, "currency"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
            expect(bundled_relation.bundled_service).to eq(bundled_service)
          end
        end
      end

      context 'when bundled_service is forever' do
        let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: nil) }

        it "creates a bundled relation without expire_at" do
          expect {
            outcome
          }.to change {
            OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
          }.by(1)

          bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
          expect(bundled_relation.expire_at).to be_nil
          expect(bundled_relation).to be_purchased_from_bundler
          expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "assignment"=> false, "currency"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
          expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
          expect(bundled_relation.bundled_service).to eq(bundled_service)
        end
      end

      context 'when bundled_service is subscription' do
        let!(:access_provider) { FactoryBot.create(:access_provider, :stripe, user: user) }
        let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
        let(:bundler_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: user) }
        let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, user: user, product: bundler_service) }
        let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true) }

        it "creates a bundled relation without expire_at" do
          expect {
            outcome
          }.to change {
            OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
          }.by(1)

          bundled_relation = OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
          expect(bundled_relation.expire_at).to be_nil
          expect(bundled_relation).to be_purchased_from_bundler
          expect(bundled_relation.product_details).to eq("prices" => [{"amount"=>nil, "assignment"=> false, "currency"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
          expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
          expect(bundled_relation.bundled_service).to eq(bundled_service)
          expect(bundled_relation.bundled_service.subscription).to eq(true)
        end
      end
    end

    context "when customer purchased online service before" do
      context "when existing relation had end time" do
        let(:existing_relation_expire_at) { Time.current.advance(days: 2).round }
        let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }

        # Customer existing service had end time => bundler service end time => pick better one
        context "when bundled service had better end time" do
          let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
          let(:better_end_time) { existing_relation_expire_at.advance(days: 1) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: better_end_time) }

          it "use bundler service expire time" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.to change {
                OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
              }

              existing_relation.reload
              expect(existing_relation).to be_pending
              expect(existing_relation.current).to be_nil

              bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to eq(better_end_time)
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
              expect(bundled_relation.permission_state).to eq("active")
              expect(bundled_relation.sale_page_id).not_to eq(existing_relation.sale_page_id)
              expect(bundled_relation.bundled_service).to eq(bundled_service)
            end
          end
        end

        # Customer existing service had end time => bundler service end time => pick better one
        context "when bundled service had worse end time" do
          let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: existing_relation_expire_at.advance(days: -1)) }

          it "use existing online_service expire time" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.to change {
                OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
              }

              existing_relation.reload
              expect(existing_relation).to be_pending
              expect(existing_relation.current).to be_nil

              bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
              expect(bundled_relation.permission_state).to eq("active")
              expect(bundled_relation.sale_page_id).not_to eq(existing_relation.sale_page_id)
              expect(bundled_relation.bundled_service).to eq(bundled_service)
            end
          end
        end

        # Customer existing service had end time => bundler service forever => replace the original one(warn customer)
        context "when bundled service was forever" do
          let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: nil) }

          it "use bundler service forever expire_at" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.to change {
                OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
              }

              existing_relation.reload
              expect(existing_relation).to be_pending
              expect(existing_relation.current).to be_nil

              bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to be_nil
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
              expect(bundled_relation.permission_state).to eq("active")
              expect(bundled_relation.sale_page_id).not_to eq(existing_relation.sale_page_id)
              expect(bundled_relation.bundled_service).to eq(bundled_service)
            end
          end
        end

        # Customer existing service had end time => bundler service recurring => replace the original one(warn customer)
        context "when bundled service was subscription" do
          let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
          let(:bundler_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: user) }
          let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, user: user, product: bundler_service) }
          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true) }

          it "use bundled service nil expire_at" do
            Timecop.freeze(Time.current.round) do
              expect {
                outcome
              }.to change {
                OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
              }

              existing_relation.reload
              expect(existing_relation).to be_pending
              expect(existing_relation.current).to be_nil

              bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
              expect(outcome.result.expire_at).to be_nil
              expect(bundled_relation).to be_purchased_from_bundler
              expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
              expect(bundled_relation.bundled_service).to eq(bundled_service)
              expect(bundled_relation.bundled_service.subscription).to eq(true)
            end
          end
        end
      end

      # existing_relation is recurring/forever
      context "when existing_relation had no end time" do
        let(:existing_relation_expire_at) { nil }

        # Customer existing service forever => bundler service end time => pick better one, still forever
        context "when existing_relation is really available forever" do
          let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
          let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
          let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
          let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }

          let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.advance(days: 3)) }

          context 'when bundled service got end time' do
            let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
            it "use existing online_service forever expire time" do
              Timecop.freeze(Time.current.round) do
                expect {
                  outcome
                }.to change {
                  OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
                }

                existing_relation.reload
                expect(existing_relation).to be_pending
                expect(existing_relation.current).to be_nil

                bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take

                expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
                expect(bundled_relation).to be_purchased_from_bundler
                expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
                expect(bundled_relation.bundled_service).to eq(bundled_service)
              end
            end
          end

          context 'when bundled service is forever' do
            let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }
            let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
            it "use existing online_service forever expire time" do
              Timecop.freeze(Time.current.round) do
                expect {
                  outcome
                }.to change {
                  OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
                }

                existing_relation.reload
                expect(existing_relation).to be_pending
                expect(existing_relation.current).to be_nil

                bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take

                expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
                expect(bundled_relation).to be_purchased_from_bundler
                expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
                expect(bundled_relation.bundled_service).to eq(bundled_service)
              end
            end
          end

          context 'when bundled service is subscription' do
            let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundled_service.online_service, customer: customer, expire_at: existing_relation_expire_at) }
            let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
            let(:bundler_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: user) }
            let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, user: user, product: bundler_service) }
            let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true) }

            it "use existing online_service forever expire time" do
              Timecop.freeze(Time.current.round) do
                expect {
                  outcome
                }.to change {
                  OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
                }

                existing_relation.reload
                expect(existing_relation).to be_pending
                expect(existing_relation.current).to be_nil

                bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take

                expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
                expect(bundled_relation).to be_purchased_from_bundler
                expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
                expect(bundled_relation.bundled_service).not_to eq(bundled_service)
                expect(bundled_relation.bundled_service_id).to eq(existing_relation.bundled_service_id)
              end
            end
          end
        end

        # Customer existing service recurring(membership) => bundler service end time(end_on_months) => still recurring, use bundler service end of month to give free bonus
        context "when existing_relation is recurring subscription" do
          let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
          let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
          let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
          let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, :paid, customer: customer, expire_at: nil) }

          context 'when bundled_service service got end time(end_on_months)' do
            let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
            let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_months: 3, online_service: existing_relation.online_service) }

            it 'is still recurring and give free bonus' do
              expect(Stripe::Coupon).to receive(:create).and_call_original
              expect(StripeSubscriptions::ApplySubscriptionCoupon).to receive(:run).and_call_original

              Timecop.freeze(Time.current.round) do
                expect {
                  outcome
                }.to change {
                  CustomerPayment.where(
                    product: existing_relation,
                    amount_cents: 0,
                    order_id: { sale_page_id: sale_page.id, bonus_month: bundled_service.end_on_months }.to_json
                  ).count
                }.by(1)

                expect(OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page)).not_to be_exists

                expect(outcome.result.expire_at).to be_nil
                expect(outcome.result).to eq(existing_relation)
              end
            end
          end

          context 'when bundled_service service is subscription' do
            let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
            let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
            let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, user: user, product: bundler_service) }
            let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
            let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
            let(:bundler_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: user) }
            let(:bundled_service) { FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true, online_service: existing_relation.online_service) }

            it "use bundled service subscription and cancel the original service subscription" do
              old_stripe_subscription_id = existing_relation.stripe_subscription_id

              Timecop.freeze(Time.current.round) do
                expect {
                  outcome
                }.to change {
                  OnlineServiceCustomerRelation.where(online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).count
                }

                bundled_relation = OnlineServiceCustomerRelation.where(current: true, online_service: bundled_service.online_service, customer: customer, sale_page: bundler_relation.sale_page).take

                expect(outcome.result.expire_at).to eq(existing_relation_expire_at)
                expect(bundled_relation).to be_purchased_from_bundler
                expect(bundled_relation.price_details).to eq(bundler_relation.price_details)
                expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
                expect(existing_relation.reload.stripe_subscription_id).to be_nil
                expect(bundled_relation.bundled_service).to eq(bundled_service)
              end
            end
          end
        end
      end
    end
  end
end