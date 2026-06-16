# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlackErrorNotifier do
  describe ".notifyable?" do
    it "does not notify request 404 errors" do
      context = { source: "Controller", request_method: "GET", request_path: "/ja/booking_pages/not-found" }
      exception = ActiveRecord::RecordNotFound.new("Couldn't find BookingPage")

      expect(described_class.notifyable?(exception, context)).to be false
    end

    it "does not notify request 400-ish routing noise" do
      context = { source: "Middleware (uncaught exception)", request_method: "GET", request_path: "/wp-login.php" }
      exception = ActionController::RoutingError.new("No route matches")

      expect(described_class.notifyable?(exception, context)).to be false
    end

    it "notifies request 500 errors" do
      context = { source: "Controller", request_method: "POST", request_path: "/ja/settings" }

      expect(described_class.notifyable?(StandardError.new("boom"), context)).to be true
    end

    it "keeps notifying non-request errors such as jobs and interactions" do
      context = { source: "Job", job_name: "CriticalJob" }

      expect(described_class.notifyable?(ActiveRecord::RecordNotFound.new("missing"), context)).to be true
    end
  end
end
