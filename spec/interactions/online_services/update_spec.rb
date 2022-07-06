# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServices::Update, :with_line do
  let(:bundler_online_service) { FactoryBot.create(:online_service, :bundler, user: customer.user) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let(:update_attribute) { 'bundled_services' }
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
      let(:online_service1) { FactoryBot.create(:online_service) }
      let(:online_service2) { FactoryBot.create(:online_service) }

      it 'updates bundled_services and approve existing available customers for new services' do
        # Existing bundled services
        bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_at: Time.current.tomorrow)
        bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: bundler_online_service, end_on_days: 3)
        bundler_relation = FactoryBot.create(:online_service_customer_relation, :paid, online_service: bundler_online_service, customer: customer)
        FactoryBot.create(:online_service_customer_relation, online_service: bundled_service_with_end_at.online_service, customer: customer)
        FactoryBot.create(:online_service_customer_relation, online_service: bundled_service_with_end_of_days.online_service, customer: customer)
        expect(online_service1.online_service_customer_relations.where(customer: customer)).not_to be_exists
        expect(online_service2.online_service_customer_relations.where(customer: customer)).not_to be_exists

        outcome

        expect(bundler_online_service.bundled_services.pluck(:online_service_id)).to match_array([
          online_service1.id,
          online_service2.id,
          bundled_service_with_end_at.online_service_id,
          bundled_service_with_end_of_days.online_service_id
        ])

        perform_enqueued_jobs
        expect(online_service1.online_service_customer_relations.where(customer: customer)).to be_exists
        expect(online_service2.online_service_customer_relations.where(customer: customer)).to be_exists
      end
    end
  end
end
