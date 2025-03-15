# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServices::Create do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let!(:profile) { FactoryBot.create(:profile, user: user) }
  let(:name) { "foo" }
  let(:selected_goal) { OnlineService.goal_types[:membership] }
  let(:selected_solution) {}
  let(:content_url) {}
  let(:end_time) {}
  let(:upsell) {}
  let(:bundled_services) { [] }
  let(:message_template) {}

  let(:args) do
    {
      user: user,
      name: name,
      selected_goal: selected_goal,
      selected_solution: selected_solution,
      content_url: content_url,
      end_time: end_time,
      upsell: upsell,
      message_template: message_template,
      bundled_services: bundled_services
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when service is not course or membership or bundler" do
      let(:selected_goal) { OnlineService.goal_types[:collection] }
      let(:selected_solution) { "video" }
      let(:content_url) { "https://google.com" }

      context "when content_url is blank" do
        let(:content_url) {}

        it "is invalid" do
          expect(outcome.errors.details[:content_url].first[:error]).to eq(:invalid)
        end
      end

      context "when selected_solution is blank" do
        let(:selected_solution) {}

        it "is invalid" do
          expect(outcome.errors.details[:selected_solution].first[:error]).to eq(:invalid)
        end
      end
    end

    context "when service is course or membership" do
      it "solution_type equals goal_type" do
        online_service = outcome.result

        expect(online_service.solution_type).to eq(online_service.goal_type)
      end
    end

    context "when service is bundler" do
      let(:selected_goal) { OnlineService.goal_types[:bundler] }
      let(:online_service1) { FactoryBot.create(:online_service) }
      let(:online_service2) { FactoryBot.create(:online_service) }
      let(:bundled_services) do
        [
          {
            id: online_service1.id
          },
          {
            id: online_service2.id
          }
        ]
      end

      it "creates bundled services without stripe" do
        online_service = outcome.result

        expect(online_service).to be_bundler
        expect(online_service.bundled_services.pluck(:online_service_id)).to match_array([online_service1.id, online_service2.id])
        expect(online_service.stripe_product_id).to be_nil
      end
    end
  end
end