# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Update do
  let(:user) { broadcast.user }
  let(:broadcast) { FactoryBot.create(:broadcast, :draft) }
  let(:params) do
    {
      content: "foo",
      query: {},
      schedule_at: nil
    }
  end
  let(:args) do
    {
      broadcast: broadcast,
      params: params
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "disabled original broadcast and create a new one" do
      expect {
        outcome
      }.not_to change {
        user.broadcasts.count
      }

      expect(broadcast).to be_disabled
    end

    context "when state is not draft" do
      let(:broadcast) { FactoryBot.create(:broadcast, :active) }

      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end
  end
end
