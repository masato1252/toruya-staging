# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalePages::UpdateRecurringPrice do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:online_service) { FactoryBot.create(:online_service, :membership, user: user) }
  let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, user: online_service.user, product: online_service) }
  let(:args) do
    {
      interval: 'month',
      amount: 1000,
      sale_page: sale_page
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context 'when price is the same(interval and amount)' do
      it "does nothing" do
        expect {
          outcome
        }.not_to change {
          sale_page.reload.recurring_prices.map(&:attributes)
        }
      end
    end

    context 'when price is different(interval and amount)' do
      let(:args) do
        {
          interval: 'month',
          amount: 2000,
          sale_page: sale_page
        }
      end

      it "creates a new price and inactive the existing one" do
        allow(Stripe::Price).to receive(:create).and_return(double(id: "price_789"))
        expect {
          outcome
        }.to change {
          sale_page.all_recurring_prices.size
        }.by(1)

        # old price was inactive, so recurring_prices was still 2
        expect(outcome.result.recurring_prices.length).to eq(2)
      end
    end

    context 'when amount is 0' do
      let(:args) do
        {
          interval: 'month',
          amount: 0,
          sale_page: sale_page
        }
      end

      it "only inactive the existing one" do
        expect {
          outcome
        }.to change {
          sale_page.recurring_prices.size
        }.from(2).to(1)

        expect(outcome.result.monthly_price).to be_nil
      end
    end

    context "when add a new interval of price" do
      let(:sale_page) { FactoryBot.create(:sale_page, user: online_service.user, product: online_service) }

      let(:args) do
        {
          interval: 'month',
          amount: 2000,
          sale_page: sale_page
        }
      end

      it "creates a new price" do
        allow(Stripe::Price).to receive(:create).and_return(double(id: "price_789"))
        expect {
          outcome
        }.to change {
          sale_page.all_recurring_prices.size
        }.by(1)

        # old price was inactive, so recurring_prices was still 2
        expect(outcome.result.recurring_prices.length).to eq(1)
        expect(outcome.result.monthly_price.amount).to eq(2_000)
      end
    end
  end
end
