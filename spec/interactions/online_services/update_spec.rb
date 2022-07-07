# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServices::Update, :with_line do
  before { StripeMock.start }
  after { StripeMock.stop }
  let!(:access_provider) { FactoryBot.create(:access_provider, :stripe, user: user) }
  let(:sale_page) { FactoryBot.create(:sale_page, product: bundler_online_service) }
  let(:bundler_online_service) { FactoryBot.create(:online_service, :with_stripe, :bundler, user: customer.user) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let(:user) { customer.user }
  let(:update_attribute) { 'bundled_services' }
  let(:online_service1) { FactoryBot.create(:online_service) }
  let(:online_service2) { FactoryBot.create(:online_service) }
  let(:attrs) do
    {
      bundled_services: [
        {
          id: online_service1.id
        },
        {
          id: online_service2.id
        }
      ]
    }
  end

  let(:args) do
    {
      online_service: bundler_online_service,
      update_attribute: update_attribute,
      attrs: attrs
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when update attribute is bundled_service" do

      it "updates bundled_services and approve existing available customers for new services" do
        # Existing bundled services
        existing_bundled_service1 = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_at: Time.current.tomorrow)
        existing_bundled_service2 = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_on_days: 3)
        bundler_relation = FactoryBot.create(:online_service_customer_relation, :paid, online_service: bundler_online_service, customer: customer)
        service_purchased_from_same_bundler_relation1 = FactoryBot.create(:online_service_customer_relation, :paid, online_service: existing_bundled_service1.online_service, customer: customer, bundled_service: existing_bundled_service1)
        service_purchased_from_same_bundler_relation2 = FactoryBot.create(:online_service_customer_relation, :paid, online_service: existing_bundled_service2.online_service, customer: customer, bundled_service: existing_bundled_service2)
        expect(online_service1.online_service_customer_relations.where(customer: customer)).not_to be_exists
        expect(online_service2.online_service_customer_relations.where(customer: customer)).not_to be_exists

        outcome

        expect(bundler_online_service.bundled_services.pluck(:online_service_id)).to match_array([
          online_service1.id,
          online_service2.id
        ])

        perform_enqueued_jobs
        expect(online_service1.online_service_customer_relations.where(customer: customer).first).to be_active
        expect(online_service2.online_service_customer_relations.where(customer: customer).first).to be_active
        expect(service_purchased_from_same_bundler_relation1.reload).to be_pending
        expect(service_purchased_from_same_bundler_relation2.reload).to be_pending
      end
    end

    context "when existing service purchased from other service and using its contract" do
      it "only affects the service using the contract from the bundler" do
        # Existing bundled services
        existing_bundled_service1 = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_at: Time.current.tomorrow)
        existing_bundled_service2 = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_on_days: 3)
        bundler_relation = FactoryBot.create(:online_service_customer_relation, :paid, online_service: bundler_online_service, customer: customer)
        service_purchased_from_same_bundler_relation = FactoryBot.create(:online_service_customer_relation, :paid, online_service: existing_bundled_service1.online_service, customer: customer, bundled_service: existing_bundled_service1)
        # This relation doesn't have bundled_service
        service_purchased_from_others_relation = FactoryBot.create(:online_service_customer_relation, :paid, online_service: existing_bundled_service2.online_service, customer: customer)

        outcome

        perform_enqueued_jobs
        expect(service_purchased_from_others_relation.reload).to be_active
        expect(service_purchased_from_same_bundler_relation.reload).to be_pending
      end
    end

    # Sale page:
    # one time payment: all bundled services need to have end time
    # recurring payment: at least one service need to be subscription
    context "when new service end time does not match sale page payment rule" do
      context 'when sale page is one time payment' do
        let!(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_online_service) }

        context 'when all bundled service got end time' do
          let(:attrs) do
            {
              bundled_services: [
                {
                  id: online_service1.id,
                  end_time: {
                    end_on_days: 30
                  }
                },
                {
                  id: online_service2.id,
                  end_time: {
                    end_on_months: 1
                  }
                }
              ]
            }
          end

          it 'is valid' do
            expect(outcome).to be_valid
          end
        end

        context 'when one bundled service got subscription' do
          let(:attrs) do
            {
              bundled_services: [
                {
                  id: online_service1.id,
                  end_time: {
                    end_on_days: 30
                  }
                },
                {
                  id: online_service2.id,
                  end_time: {
                    end_type: "subscription"
                  }
                }
              ]
            }
          end

          it 'is invalid' do
            expect(outcome).to be_invalid
          end
        end
      end

      context 'when sale page is recurring payment' do
        let!(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, product: bundler_online_service, user: user) }

        context 'when all bundled service got end time' do
          let(:attrs) do
            {
              bundled_services: [
                {
                  id: online_service1.id,
                  end_time: {
                    end_on_days: 30
                  }
                },
                {
                  id: online_service2.id,
                  end_time: {
                    end_on_months: 1
                  }
                }
              ]
            }
          end

          it 'is invalid' do
            expect(outcome).to be_invalid
          end
        end

        context 'when one bundled service got subscription' do
          let(:attrs) do
            {
              bundled_services: [
                {
                  id: online_service1.id,
                  end_time: {
                    end_on_days: 30
                  }
                },
                {
                  id: online_service2.id,
                  end_time: {
                    end_type: "subscription"
                  }
                }
              ]
            }
          end

          it 'is valid' do
            expect(outcome).to be_valid
          end
        end
      end
    end
  end
end
