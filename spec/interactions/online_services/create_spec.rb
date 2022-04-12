# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServices::Create do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:name) { "foo" }
  let(:selected_goal) { OnlineService.goal_types[:membership] }
  let(:selected_solution) {}
  let(:content_url) {}
  let(:end_time) {}
  let(:upsell) {}
  let(:selected_company) do
    {
      type: shop.class.to_s,
      id: shop.id
    }
  end
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
      selected_company: selected_company,
      message_template: message_template
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when service is not course or membership" do
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

    context "when service is recurring(membership)" do
      it "creates a stripe product" do
        online_service = outcome.result

        expect(
          Stripe::Product.retrieve(
            online_service.stripe_product_id,
            {
              stripe_account: online_service.user.stripe_provider.uid
            }
          )
        ).to be_present
      end
    end
  end
end
