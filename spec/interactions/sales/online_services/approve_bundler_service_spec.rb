# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::ApproveBundlerService, :with_line do
  let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_service) }
  let(:bundler_service) { FactoryBot.create(:online_service, :bundler, user: user) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let!(:bundler_relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, sale_page: sale_page, online_service: bundler_service, customer: customer) }
  let(:user) { customer.user }
  let(:args) do
    {
      relation: bundler_relation
    }
  end
  let(:outcome) { described_class.run(args) }
  # Bundler service:  service item 1  end time    => sale page one time, recurring pay  => one time      => item1 had end time, item2 is real forever
  #                   service item 2  forever                                           => recurring pay => item1 had end time item2 would be ended if charged failed
  #                   service item 3 (membership) only end_on_months
  #
  # Bundler service:  service item 1  end time    => sale page one time
  #                   service item 2  end time
  #
  # Bundler service:  service item 1  forever     => sale page one time, recurring pay  => one time      => item1, item2 is real forever
  #                   service item 2  forever                                           => recurring pay => item1, item2 would be ended if bundler charged failed

  describe "#execute" do
    context 'when approve for a bundler service' do
      context 'when bundler service had both services had end time' do
        it 'both online_service_customer_relation had expire_at' do
          Timecop.freeze do
            bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
            bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_on_days: 3)

            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.count
            }.by(2)

            expect(bundler_relation.expire_at).to be_nil
            relation_with_end_at_service = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_end_at_service.expire_at).to eq(Time.current.tomorrow)
            expect(relation_with_end_at_service).to be_purchased_from_bundler
            expect(relation_with_end_at_service.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_end_at_service.price_details).to eq(bundler_relation.price_details)

            relation_with_end_of_days_service = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_end_of_days.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_end_of_days_service.expire_at).to eq(Time.current.advance(days: 3))
            expect(relation_with_end_of_days_service).to be_purchased_from_bundler
            expect(relation_with_end_of_days_service.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_end_of_days_service.price_details).to eq(bundler_relation.price_details)
          end
        end
      end

      context 'when bundler service had both services is forever' do
        it 'both online_service_customer_relation had no expire_at(forever available)' do
          Timecop.freeze do
            bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
            bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)

            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.count
            }.by(2)

            relation_with_end_at_service = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_end_at_service.expire_at).to eq(Time.current.tomorrow)
            expect(relation_with_end_at_service).to be_purchased_from_bundler
            expect(relation_with_end_at_service.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_end_at_service.price_details).to eq(bundler_relation.price_details)

            relation_with_forever_service = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_forever.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_forever_service.expire_at).to be_nil
            expect(relation_with_forever_service).to be_purchased_from_bundler
            expect(relation_with_forever_service.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_forever_service.price_details).to eq(bundler_relation.price_details)
          end
        end
      end

      context 'when bundler service had one service had end time, another is forever' do
        it 'one online_service_customer_relation expire_at, another do NOT(forever available)' do
          Timecop.freeze do
            bundled_service_with_forever1= FactoryBot.create(:bundled_service, bundler_service: bundler_service)
            bundled_service_with_forever2 = FactoryBot.create(:bundled_service, bundler_service: bundler_service)

            expect {
              outcome
            }.to change {
              OnlineServiceCustomerRelation.count
            }.by(2)

            relation_with_forever_service1 = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_forever1.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_forever_service1.expire_at).to be_nil
            expect(relation_with_forever_service1).to be_purchased_from_bundler
            expect(relation_with_forever_service1.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_forever_service1.price_details).to eq(bundler_relation.price_details)

            relation_with_forever_service2 = OnlineServiceCustomerRelation.where(online_service: bundled_service_with_forever2.online_service, customer: customer, sale_page: bundler_relation.sale_page).take
            expect(relation_with_forever_service2.expire_at).to be_nil
            expect(relation_with_forever_service2).to be_purchased_from_bundler
            expect(relation_with_forever_service2.product_details).to eq("prices" => [{"amount"=>nil, "bundler_price"=>true, "charge_at"=>nil, "interval"=>nil, "order_id"=>nil, "stripe_price_id"=>nil}])
            expect(relation_with_forever_service2.price_details).to eq(bundler_relation.price_details)
          end
        end
      end
    end

    # context 'when recurring pay for a bundler service' do
    #   let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, online_service: bundler_service, customer: customer) }
    #
    #   context 'when bundler service had both services had end time' do
    #     it 'is invalid'
    #   end
    #
    #   context 'when bundler service had both services is forever' do
    #     it 'both online_service_customer_relation had no expire_at(forever available)' do
    #     end
    #   end
    #
    #   context 'when bundler service had one service had end time, another is forever' do
    #     it 'both online_service_customer_relation had no expire_at(forever available)' do
    #     end
    #   end
    # end
  end
end
