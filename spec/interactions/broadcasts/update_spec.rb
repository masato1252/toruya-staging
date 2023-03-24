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
  let(:update_attribute) { "content" }
  let(:args) do
    {
      broadcast: broadcast,
      params: params,
      update_attribute: update_attribute
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when state is not draft" do
      let(:broadcast) { FactoryBot.create(:broadcast, :active) }

      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end

    context "when broadcast schedule_at changed" do
      let(:new_schedule_time) { Time.current.tomorrow }
      let(:update_attribute) { "schedule_at" }
      let(:params) do
        {
          content: "foo",
          query: {},
          schedule_at: new_schedule_time
        }
      end

      it "schedules a new job" do
        expect(Broadcasts::Send).to receive(:perform_at).with(schedule_at: new_schedule_time, broadcast: broadcast)

        outcome
      end
    end
  end
end
