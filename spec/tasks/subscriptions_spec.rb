require "rails_helper"
require "pending_reservations_summary_job"

RSpec.describe "rake subscriptions:charge" do
  context "when today is before subscription's charge date" do
    context "when today is the last day of the month" do
      it "charges user"
    end

    context "when today is not the last day of the month" do
      it "do nothing"
    end
  end

  context "when today is equal subscription's charge date" do
    it "charges user"

    context "when user subscribe free plan" do
      it "do nothing"
    end
  end

  context "when today is over subscription's charge date" do
    it "do nothing"
  end
end
