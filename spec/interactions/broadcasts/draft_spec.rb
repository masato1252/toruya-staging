# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Draft do
  let(:broadcast) { FactoryBot.create(:broadcast) }
  let(:args) do
    {
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "drafts broadcasts" do
      expect {
        outcome
      }.to change {
        broadcast.state
      }.to("draft")
    end

    context "when state is not active" do
      let(:broadcast) { FactoryBot.create(:broadcast, :final) }

      it "does nothing" do
        expect {
          outcome
        }.not_to change {
          broadcast.state
        }
      end
    end
  end
end
