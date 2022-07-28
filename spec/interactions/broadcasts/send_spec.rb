# frozen_string_literal: true

require "rails_helper"

RSpec.describe Broadcasts::Send do
  let(:user) { broadcast.user }
  let(:broadcast) { FactoryBot.create(:broadcast) }
  let(:schedule_at) { nil }
  let(:args) do
    {
      broadcast: broadcast,
      schedule_at: schedule_at
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

    context 'when broadcast changed schedule time' do
      let(:new_schedule_at) { 20.minutes.from_now }
      let(:legacy_schedule_at) { 10.minutes.from_now }
      let(:broadcast) { FactoryBot.create(:broadcast, schedule_at: legacy_schedule_at) }

      it do
        Broadcasts::Send.perform_at(schedule_at: broadcast.schedule_at, broadcast: broadcast)
        broadcast.update(schedule_at: new_schedule_at)
        Broadcasts::Send.perform_at(schedule_at: broadcast.schedule_at, broadcast: broadcast)
        expect(Broadcasts::FilterCustomers).to receive(:run) do |args|
          expect(args[:broadcast].schedule_at).to eq(new_schedule_at)
        end.once.and_call_original

        perform_enqueued_jobs
      end
    end
  end
end
