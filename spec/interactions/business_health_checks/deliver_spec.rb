# frozen_string_literal: true

require "rails_helper"

RSpec.describe BusinessHealthChecks::Deliver do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:user) { subscription.user }
  let!(:social_account) { FactoryBot.create(:social_account, user: user) }
  let(:social_user) { FactoryBot.create(:social_user, user: user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user, created_at: 31.days.ago) }
  let!(:sale_page) { FactoryBot.create(:sale_page, user: user, product: booking_page) }
  before { user.create_user_metric }

  let(:args) do
    {
      subscription: subscription
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when customer doesn't have enough messages" do
      it "delivers no enough message" do
        expect(Notifiers::Users::BusinessHealthChecks::NoEnoughMessage).to receive(:run).with(receiver: user)

        outcome
      end
    end

    context "when customer has enough messages" do
      before do
        stub_const("BusinessHealthChecks::Deliver::MESSAGES_FROM_CUSTOMER_CRITERIA", 1)
        FactoryBot.create(:social_message, :customer, social_account: social_account)
      end

      context "when non booking page doesn't had enough page views" do
        it "delivers not enough booking page views first time reminder message" do
          allow(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).to receive(:run)

          outcome

          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).to have_received(:run).with(
            receiver: user
          )
        end
      end

      context "when user already received first message" do
        before do
          FactoryBot.create(:custom_message, scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW, nth_time: 1, service: nil, after_days: 0)
          FactoryBot.create(:social_user_message, scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW, nth_time: 1, social_user: social_user)
        end

        it "delivers not enough booking page views 1st reminder message twice" do
          expect(LineClient).to receive(:send).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).to receive(:run).with(receiver: user).and_call_original
          outcome

          perform_enqueued_jobs
          expect(SocialUserMessage.where(
            scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW,
            nth_time: 1,
            social_user: social_user
          ).count).to eq(2)
        end

        context "when custom message for 2nd times fit the condition" do
          before do
            FactoryBot.create(:custom_message, scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW, nth_time: 2, service: nil, after_days: 0)
          end

          it "delivers not enough booking page views 2nd reminder message" do
            expect(LineClient).to receive(:send).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
            expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).to receive(:run).with(receiver: user).and_call_original
            outcome

            perform_enqueued_jobs
            expect(SocialUserMessage.where(
              scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW,
              nth_time: 2,
              social_user: social_user
            ).count).to eq(1)
          end
        end
      end

      context "when booking page had enough page views" do
        before do
          stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_VISIT_CRITERIA", 1)
          # 2 page views
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
        end

        it "does nothing" do
          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).not_to receive(:run)

          outcome
        end

        context "when booking page does NOT have enough conversion rate" do
          before do
            stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_CONVERSION_RATE_CRITERIA", 1)
          end

          it "delivers not enough booking first time reminder message" do
            allow(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).to receive(:run)

            outcome

            expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).to have_received(:run).with(
              receiver: user
            )
          end

          context "when user already received first message" do
            before do
              FactoryBot.create(:custom_message, scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_BOOKING, nth_time: 1, service: nil, after_days: 0)
              FactoryBot.create(:social_user_message, scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_BOOKING, nth_time: 1, social_user: social_user)
            end

            it "delivers not enough booking second time reminder message" do
              expect(LineClient).to receive(:send).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
              expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).to receive(:run).with(receiver: user).and_call_original
              outcome

              perform_enqueued_jobs
              expect(SocialUserMessage.where(
                scenario: ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_BOOKING,
                nth_time: 1,
                social_user: social_user
              ).count).to eq(2)
            end
          end
        end
      end

      context "when booking page had enough page views and enough conversion rate" do
        before do
          stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_VISIT_CRITERIA", 1)
          stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_CONVERSION_RATE_CRITERIA", 0.01)
          # 2 page views
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
        end

        it "does nothing" do
          FactoryBot.create(:reservation_customer, reservation: FactoryBot.create(:reservation, user: user), booking_page: sale_page.product)
          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView).not_to receive(:run)
          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).not_to receive(:run)

          outcome
        end

        context "when no new customer for a period(no purchase in 60 days)" do
          it "delivers no new customer reminder message" do
            FactoryBot.create(:reservation_customer, reservation: FactoryBot.create(:reservation, user: user), booking_page: sale_page.product)
            FactoryBot.create(:social_customer, user: user, created_at: 61.days.ago)
            allow(Notifiers::Users::BusinessHealthChecks::NoNewCustomer).to receive(:run)

            outcome

            expect(Notifiers::Users::BusinessHealthChecks::NoNewCustomer).to have_received(:run).with(
              receiver: user
            )
          end
        end
      end

      context 'when not the same page had enough booking page and conversion rate' do
        before do
          stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_VISIT_CRITERIA", 1)
          stub_const("BusinessHealthChecks::Deliver::BOOKING_PAGE_CONVERSION_RATE_CRITERIA", 0.01)
          # 2 page views
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
          FactoryBot.create(:ahoy_visit, product: sale_page.product, owner: user)
        end

        it "delivers not enough booking first time reminder message" do
          other_booking_page = FactoryBot.create(:booking_page, user: user, created_at: 31.days.ago)
          FactoryBot.create(:reservation_customer, reservation: FactoryBot.create(:reservation, user: user), booking_page: other_booking_page)
          allow(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).to receive(:run)

          outcome

          expect(Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking).to have_received(:run).with(
            receiver: user
          )
        end
      end
    end
  end
end