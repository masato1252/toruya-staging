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

  context "when current time is not around Japan 7AM or 5PM" do
    let(:current_time) { Time.use_zone("Tokyo") { Time.zone.local(2021, 8, 4, 10, 0, 0) } }

    it "does nothing" do
      expect(Notifiers::Users::PendingTasksSummary).not_to receive(:perform_at)
      task.execute
    end
  end

  context "when current time is Japan 7AM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 7, 0, 0) }

    it "schedules the notification jobs" do
      expect(Notifiers::Users::PendingTasksSummary).to receive(:perform_at).once
      task.execute
    end
  end

  context "when current time is Japan 5PM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 17, 0, 0) }

    it "schedules the notification jobs" do
      expect(Notifiers::Users::PendingTasksSummary).to receive(:perform_at).once
      task.execute
    end
  end
end
