# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::LineSettings::FinishedFlex do
  let(:receiver) { FactoryBot.create(:social_user).user }
  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a user message", :with_line do
      expect {
        outcome
      }.to change {
        SocialUserMessage.where(social_user: receiver.social_user, content_type: SocialUserMessages::Create::FLEX_TYPE).count
      }.by(1)
    end
  end
end
