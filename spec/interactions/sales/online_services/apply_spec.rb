# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Apply do
  let(:current_time) { Time.current }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:sale_page) { FactoryBot.create(:sale_page, :online_service, user: user) }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }
  let(:payment_type) { SalePage::PAYMENTS[:free] }
  let(:args) do
    {
      sale_page: sale_page,
      customer: customer,
      online_service: sale_page.product,
      payment_type: payment_type
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a new online_service_customer_relation" do
      expect {
        outcome
      }.to change {
        OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer, sale_page: sale_page).count
      }.by(1)

      latest_relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer, sale_page: sale_page).last
      expect(latest_relation).to have_attributes(
        current: true,
        payment_state: "pending",
        permission_state: "pending"
      )
      price_details = latest_relation.price_details.first
      expect(price_details).to have_attributes(
        amount: Money.zero,
        order_id: nil
      )
    end

    context 'when sale page is a one time payment' do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :one_time_payment, user: user) }
      let(:payment_type) { SalePage::PAYMENTS[:one_time] }

      it "creates a new online_service_customer_relation with expected price details" do
        outcome

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer, sale_page: sale_page).last
        price_details = relation.price_details.first
        expect(price_details).to have_attributes(
          amount: sale_page.selling_price_amount,
          charge_at: current_time.as_json
        )
        expect(price_details.order_id).to be_present
      end
    end

    context 'when sale page is a multiple times payment' do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, user: user, selling_multiple_times_price: [1000, 1000]) }
      let(:payment_type) { SalePage::PAYMENTS[:multiple_times] }

      it "creates a new online_service_customer_relation with expected price details" do
        outcome

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer, sale_page: sale_page).last
        expect(relation.price_details.size).to eq(2)

        first_price_details = relation.price_details.first
        expect(first_price_details).to have_attributes(
          amount: Money.new(1000),
          charge_at: current_time.as_json
        )
        expect(first_price_details.order_id).to be_present

        second_price_details = relation.price_details.second
        expect(second_price_details).to have_attributes(
          amount: Money.new(1000),
          charge_at: current_time.advance(months: 1).as_json
        )
        expect(second_price_details.order_id).to be_present
      end
    end

    context 'when customer already connected with a online service' do
      let!(:existing_relation) { FactoryBot.create(:online_service_customer_relation, online_service: sale_page.product, customer: customer) }

      it "returns existing relation" do
        expect {
          outcome
        }.not_to change {
          OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).count
        }

        expect(outcome.result).to eq(existing_relation)
      end
    end
  end
end
