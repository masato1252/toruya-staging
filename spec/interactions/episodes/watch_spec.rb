# frozen_string_literal: true

require "rails_helper"

RSpec.describe Episodes::Watch do
  let(:customer) { online_service_customer_relation.customer }
  let(:online_service) { online_service_customer_relation.online_service }
  let(:episode) { FactoryBot.create(:episode, online_service: online_service) }
  let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  let(:args) do
    {
      customer: customer,
      episode: episode
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates watched_episode_ids" do
      outcome

      expect(online_service_customer_relation.reload.watched_episode_ids).to eq([episode.id.to_s])
    end
  end
end
