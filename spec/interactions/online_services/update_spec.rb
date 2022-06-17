# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServices::Update do
  let(:online_service) { FactoryBot.create(:online_service) }
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
      online_service: online_service,
      update_attribute: update_attribute,
      attrs: attrs
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when update attribute is bundled_service" do
      let(:online_service1) { FactoryBot.create(:online_service) }
      let(:online_service2) { FactoryBot.create(:online_service) }

      it 'updates bundled_services' do
        bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: online_service, end_at: Time.current.tomorrow)
        bundled_service_with_end_of_days = FactoryBot.create(:bundled_service, bundler_service: online_service, end_on_days: 3)

        outcome

        expect(online_service.bundled_services.pluck(:online_service_id)).to match_array([online_service1.id, online_service2.id])
      end
    end
  end
end
