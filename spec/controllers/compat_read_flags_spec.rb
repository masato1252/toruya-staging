# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompatReadFlags do
  subject(:flags) do
    Class.new do
      include CompatReadFlags

      attr_reader :session

      def initialize
        @session = {}
      end

      def params
        {}
      end
    end.new
  end

  around do |example|
    original = ENV.to_hash.slice(
      "COMPAT_API_ORIGIN",
      "COMPAT_API_READ_ENABLED",
      "COMPAT_ADMIN_ENABLED",
      "COMPAT_EVENT_ENABLED"
    )
    ENV["COMPAT_API_ORIGIN"] = "https://api.example.test"
    example.run
  ensure
    %w[
      COMPAT_API_ORIGIN
      COMPAT_API_READ_ENABLED
      COMPAT_ADMIN_ENABLED
      COMPAT_EVENT_ENABLED
    ].each { |key| ENV.delete(key) }
    original.each { |key, value| ENV[key] = value }
  end

  it "switches Admin independently from owner compat reads" do
    ENV["COMPAT_API_READ_ENABLED"] = "true"
    ENV["COMPAT_ADMIN_ENABLED"] = "false"
    expect(flags.compat_admin_enabled?).to be(false)

    ENV["COMPAT_ADMIN_ENABLED"] = "true"
    expect(flags.compat_admin_enabled?).to be(true)
  end

  it "exposes the event env flag independently from owner migration" do
    ENV["COMPAT_EVENT_ENABLED"] = "false"
    expect(flags.compat_event_enabled?).to be(false)

    ENV["COMPAT_EVENT_ENABLED"] = "true"
    expect(flags.compat_event_enabled?).to be(true)
  end

  it "enables the event frontend meta tag for compat bootstrap pages" do
    flags.instance_variable_set(:@compat_public_read, true)
    expect(flags.compat_event_frontend_enabled?).to be(true)
  end

  it "keeps the event frontend legacy unless its dedicated flag and owner migration are active" do
    allow(DataPlaneMigration).to receive(:migrated?).with(83).and_return(true)
    ENV["COMPAT_EVENT_ENABLED"] = "false"
    expect(flags.compat_public_event_for_owner?(83)).to be(false)

    ENV["COMPAT_EVENT_ENABLED"] = "true"
    expect(flags.compat_public_event_for_owner?(83)).to be(true)
  end
end
