# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::ScheduleCharges do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :multiple_times_payment) }
  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "schedules all the unpaid payments charge tasks and reminders" do
      expect(CustomerPayments::PurchaseOnlineService).to receive(:perform_at).twice

      outcome
    end

    context "when there is one order was paid" do
      let!(:paid_payment) { FactoryBot.create(:customer_payment, :completed, product: relation.sale_page, customer: relation.customer, order_id: relation.price_details.first.order_id) }

      it "schedules all the unpaid payments charge tasks and reminders" do
        allow(Notifiers::OnlineServices::ChargeReminder).to receive(:perform_at)
        allow(CustomerPayments::PurchaseOnlineService).to receive(:perform_at)

        outcome

        expect(Notifiers::OnlineServices::ChargeReminder).to have_received(:perform_at).with(
          schedule_at: relation.price_details.last.charge_at.advance(days: -7),
          receiver: relation.customer,
          online_service_customer_relation: relation,
          online_service_customer_price: relation.price_details.last
        )
        expect(CustomerPayments::PurchaseOnlineService).to have_received(:perform_at).with(
          schedule_at: relation.price_details.last.charge_at,
          online_service_customer_relation: relation,
          online_service_customer_price: relation.price_details.last
        ).once
      end
    end
  end
end
