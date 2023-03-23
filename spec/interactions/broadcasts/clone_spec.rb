# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Clone do
  let(:broadcast) { FactoryBot.create(:broadcast, :final, schedule_at: Time.current) }
  let(:args) do
    {
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "create a new broadcast" do
      expect {
        outcome
      }.to change {
        Broadcast.count
      }.to(2)

      new_broadcast = Broadcast.last
      expect(new_broadcast.user_id).to eq(broadcast.user_id)
      expect(new_broadcast.query).to eq(broadcast.query)
      expect(new_broadcast.schedule_at).to be_nil
      expect(new_broadcast).to be_draft
    end
  end
end
