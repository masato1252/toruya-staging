# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Send do
  let(:user) { broadcast.user }
  let(:broadcast) { FactoryBot.create(:broadcast) }
  let(:args) do
    {
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sent broadcasts" do
      outcome

      expect(broadcast).to be_final
      expect(broadcast.sent_at).to be_present
    end

    context "when state is not active" do
      let(:broadcast) { FactoryBot.create(:broadcast, :draft) }

      it "does nothing" do
        outcome

        expect(broadcast).to be_draft
        expect(broadcast.sent_at).to be_nil
      end
    end
  end
end
