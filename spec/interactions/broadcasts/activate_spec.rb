# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Activate do
  let(:broadcast) { FactoryBot.create(:broadcast) }
  let(:args) do
    {
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when schedule_at is nil" do
      let(:broadcast) { FactoryBot.create(:broadcast, :draft, schedule_at: nil) }

      it "schedules a new job" do
        expect(Broadcasts::Send).to receive(:perform_at).with(schedule_at: broadcast.schedule_at, broadcast: broadcast)

        outcome
      end
    end

    context "when schedule_at was passed" do
      let(:broadcast) { FactoryBot.create(:broadcast, :draft, schedule_at: Time.current.yesterday.round) }

      it "schedules a new job" do
        expect(Broadcasts::Send).to receive(:perform_at).with(schedule_at: broadcast.schedule_at.round, broadcast: broadcast)

        outcome
      end
    end

    context "when schedule_at is in the future" do
      let(:broadcast) { FactoryBot.create(:broadcast, :draft, schedule_at: Time.current.tomorrow) }

      it "doesn't schedule a new job" do
        expect(Broadcasts::Send).not_to receive(:perform_at)

        outcome
      end
    end
  end
end
