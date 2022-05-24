# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::UserSignedUp do
  let(:receiver) { FactoryBot.create(:user) }
  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "doesn't call line directly because there is no message by default" do
      expect(::CustomMessages::Users::Next).to receive(:run)

      outcome
    end

    context "when there is are some custom messages" do
      it "schedules next custom_message" do
        FactoryBot.create(:custom_message, :user_signed_up_scenario, after_days: 0)
        FactoryBot.create(:custom_message, :user_signed_up_scenario, after_days: 0)
        FactoryBot.create(:custom_message, :user_signed_up_scenario, after_days: 1)

        expect(Notifiers::Users::CustomMessages::Send).to receive(:perform_at).twice
        outcome
      end
    end
  end
end
