# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake notifications:pending_tasks" do
  let(:current_time) { Time.now }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
    FactoryBot.create(:user, customer_latest_activity_at: current_time.advance(hours: -1))
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  context "when current time is not around Japan 8AM" do
    let(:current_time) { Time.use_zone("Tokyo") { Time.zone.local(2021, 8, 4, 8, 0, 1) } }

    it "do nothing" do
      expect(Notifiers::PendingTasksSummary).not_to receive(:perform_later)

      task.execute
    end
  end

  context "when current time is Japan 7AM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 7, 59, 59) }

    it "sends the jobs to user" do
      expect(Notifiers::PendingTasksSummary).to receive(:perform_later).once
      task.execute
    end
  end

  context "when current time is Japan 8PM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 17, 59, 59) }

    it "sends the jobs to user" do
      expect(Notifiers::PendingTasksSummary).to receive(:perform_later).once
      task.execute
    end
  end
end
