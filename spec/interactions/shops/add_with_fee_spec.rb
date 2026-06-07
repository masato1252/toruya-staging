# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shops::AddWithFee do
  let(:subscription) { FactoryBot.create(:subscription, :premium, :with_stripe) }
  let(:user) { subscription.user }
  let(:source_shop) { user.shops.first }

  before do
    Time.zone = "Tokyo"
    Timecop.freeze(Date.new(2018, 1, 15))
    StripeMock.start
    subscription.update!(expired_date: Date.new(2018, 1, 31))
        FactoryBot.create(
          :subscription_charge,
          :completed,
          :plan_subscruption,
          user: user,
          plan: subscription.plan,
          charge_date: Date.new(2018, 1, 1),
          expired_date: Date.new(2018, 1, 31),
          amount_cents: 5500
        )
    BusinessSchedules::Create.run!(
      shop: source_shop,
      attrs: {
        day_of_week: 1,
        business_state: "opened",
        start_time: "09:00",
        end_time: "20:00"
      }
    )
  end

  after do
    Timecop.return
    StripeMock.stop
  end

  describe "#execute" do
    context "when shop fee is required" do
      before do
        successful_intent = double(
          status: "succeeded",
          as_json: { "id" => "pi_success_123", "status" => "succeeded" }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_intent)
        allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "charges prorated fee and creates shop with copied schedules" do
        schedule_count = source_shop.business_schedules.for_shop.count
        acting_staff = user.staffs.first

        outcome = described_class.run(user: user, acting_staff: acting_staff, authorize_token: "pm_test_123")

        expect(outcome).to be_valid
        shop = outcome.result
        expect(shop.name).to end_with("(NEW)")
        expect(shop.short_name).to end_with("(NEW)")
        expect(acting_staff.reload.shop_ids).to include(shop.id)
        expect(shop.info_setup_completed).to be(false)
        expect(schedule_count).to be >= 1
        expect(shop.business_schedules.for_shop.count).to eq(schedule_count)
        copied = shop.business_schedules.for_shop.find_by(day_of_week: 1)
        expect(copied.business_state).to eq("opened")
        expect(copied.start_time.strftime("%H:%M")).to eq("09:00")
        expect(copied.end_time.strftime("%H:%M")).to eq("20:00")
        expect(user.subscription_charges.last.shop_fee?).to be(true)
      end
    end

    context "when charge fails" do
      before do
        failed_intent = double(
          status: "requires_payment_method",
          as_json: { "id" => "pi_failed_123", "status" => "requires_payment_method" },
          last_payment_error: nil,
          client_secret: "secret"
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(failed_intent)
        allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "does not create a new shop" do
        expect {
          described_class.run(user: user, authorize_token: "pm_test_123")
        }.not_to change { user.shops.count }
      end
    end

    context "when user is enterprise" do
      let(:subscription) { FactoryBot.create(:subscription, plan: Plan.enterprise_level.take) }

      it "creates shop without charging" do
        expect(Subscriptions::ShopFeeCharge).not_to receive(:run)

        outcome = described_class.run(user: user)
        expect(outcome).to be_valid
        expect(outcome.result.info_setup_completed).to be(false)
      end
    end
  end
end
