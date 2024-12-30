# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Price do
  let(:free_customer_limit) { 1 }
  let(:basic_customer_limit) { 2 }
  let(:basic_customer_max_limit) { 5 }
  let(:subscription) { FactoryBot.create(:subscription, :free) }
  let(:user) { subscription.user }
  let(:args) do
    {
      user: user,
      plan: plan,
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    stub_const("Plan::DETAILS_OLD", {
      Plan::FREE_LEVEL => [
        {
          rank: 0,
          max_customers_limit: free_customer_limit,
          cost: 0
        },
        {
          rank: 1,
          max_customers_limit: Float::INFINITY,
        }
      ],
      Plan::BASIC_LEVEL => [
        {
          rank: 0,
          max_customers_limit: basic_customer_limit,
          cost: 2_200,
        },
        {
          rank: 1,
          max_customers_limit: basic_customer_max_limit,
          cost: 3_000,
        },
        {
          rank: 2,
          max_customers_limit: Float::INFINITY
        },
      ]
    })
  end

  describe "#execute" do
    context "when plan is free" do
      let(:plan) { Plan.free_level.take }

      it "returns expected cost" do
        expect(outcome.result).to eq([Money.zero, 0])
      end

      context "when user's customers more than the limit" do
        it "returns expected cost" do
          FactoryBot.create_list(:customer, free_customer_limit + 1, user: user)

          expect(outcome.result).to eq([Money.zero, 1])
        end
      end
    end

    context "when plan is basic" do
      let(:plan) { Plan.basic_level.take }

      context "when user's customers fewer than the limit" do
        it "returns expected cost" do
          FactoryBot.create_list(:customer, basic_customer_limit - 1, user: user)

          expect(outcome.result).to eq([2_200.to_money(:jpy), 0])
        end
      end

      context "when user's customers equal the limit" do
        it "returns expected cost" do
          FactoryBot.create_list(:customer, basic_customer_limit, user: user)

          expect(outcome.result).to eq([2_200.to_money(:jpy), 0])
        end
      end

      context "when user's customers more than the limit" do
        it "returns expected cost" do
          FactoryBot.create_list(:customer, basic_customer_limit + 1, user: user)

          expect(outcome.result).to eq([3_000.to_money(:jpy), 1])
        end
      end

      context "when user's current plan rank is higher than the new one" do
        let(:subscription) { FactoryBot.create(:subscription, :basic, rank: 1) }

        it "returns expected cost" do
          FactoryBot.create_list(:customer, basic_customer_limit - 1, user: user)

          expect(outcome.result).to eq([3_000.to_money(:jpy), 1])
        end
      end

      context "when rank is highest" do
        it "returns error" do
          FactoryBot.create_list(:customer, basic_customer_max_limit+ 1, user: user)

          expect(outcome.errors.details[:plan]&.first&.dig(:error)).to eq(:invalid_price)
        end
      end
    end

    context "after 2025-01-10" do
      let(:frozen_time) { Time.zone.local(2025, 1, 11) }

      before do
        Timecop.freeze(frozen_time)
        stub_const("Plan::DETAILS_JP", {
          Plan::FREE_LEVEL => [
            {
              rank: 0,
              max_customers_limit: free_customer_limit,
              cost: 0
            },
            {
              rank: 1,
              max_customers_limit: Float::INFINITY,
            }
          ],
          Plan::BASIC_LEVEL => [
            {
              rank: 0,
              max_customers_limit: basic_customer_limit,
              cost: 2_200,
            },
            {
              rank: 1,
              max_customers_limit: basic_customer_max_limit,
              cost: 3_000,
            },
            {
              rank: 2,
              max_customers_limit: Float::INFINITY
            },
          ]
        })
      end

      after do
        Timecop.return
      end
      context "when plan is basic" do
        let(:plan) { Plan.basic_level.take }

        context "when user's customers fewer than the limit" do
          it "returns expected cost" do
            FactoryBot.create_list(:customer, basic_customer_limit - 1, user: user)

            expect(outcome.result).to eq([2_200.to_money(:jpy), 0])
          end

        end

        context "when user's customers equal the limit" do
          it "returns expected cost" do
            FactoryBot.create_list(:customer, basic_customer_limit, user: user)

            expect(outcome.result).to eq([2_200.to_money(:jpy), 0])
          end
        end

        context "when user's customers more than the limit" do
          it "returns expected cost" do
            FactoryBot.create_list(:customer, basic_customer_limit + 1, user: user)

            expect(outcome.result).to eq([3_000.to_money(:jpy), 1])
          end
        end

        context "when user's current plan rank is higher than the new one" do
          let(:subscription) { FactoryBot.create(:subscription, :basic, rank: 1) }

          it "returns expected cost" do
            FactoryBot.create_list(:customer, basic_customer_limit - 1, user: user)

            expect(outcome.result).to eq([3_000.to_money(:jpy), 1])
          end
        end

        context "when rank is highest" do
          it "returns error" do
            FactoryBot.create_list(:customer, basic_customer_max_limit+ 1, user: user)

            expect(outcome.errors.details[:plan]&.first&.dig(:error)).to eq(:invalid_price)
          end
        end
      end
    end
  end
end
