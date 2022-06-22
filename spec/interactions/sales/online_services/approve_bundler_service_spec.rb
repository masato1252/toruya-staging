# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::ApproveBundlerService, :with_line do
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer) }
  let(:customer) { FactoryBot.create(:social_customer).customer }
  let(:online_service) { relation.online_service }
  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context 'when '
  end
end
