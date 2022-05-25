# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::LineSettings::LineLoginVerificationFlex do
  let(:social_user) { FactoryBot.create(:social_user) }
  let(:receiver) { FactoryBot.create(:social_customer, user: social_user.user).customer }
  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a customer message", :with_line do
      expect {
        outcome
      }.to change {
        SocialMessage.where(social_customer: receiver.social_customer, content_type: SocialMessages::Create::FLEX_TYPE).count
      }.by(1)
    end
  end
end
