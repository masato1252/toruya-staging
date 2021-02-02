# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profiles::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:params) do
    {
      last_name: "foo",
      first_name: "foo",
      phonetic_last_name: "foo",
      phonetic_first_name: "foo",
      address: "foo",
      phone_number: "foo",
      zip_code: "foo",
    }
  end
  let(:args) do
    {
      user: user,
      params: params,
    }
  end
  let(:outcome) { described_class.run!(args) }

  describe "#execute" do
    it "creates a profile" do
      expect {
        outcome
      }.to change {
        Profile.count
      }.by(1)
    end

    context "when user got a reference" do
      before do
        factory.create_referral(referrer: user)
      end

      it "has a new_referrer mail" do
        allow(Notifiers::Notifications::NewReferrer).to receive(:perform_later).with(
          receiver: user.reference.referee,
          user: user.reference.referee
        ).and_return(spy(deliver_later: true))

        outcome

        expect(Notifiers::Notifications::NewReferrer).to have_received(:perform_later).with(
          receiver: user.reference.referee,
          user: user.reference.referee
        )
      end
    end
  end
end
