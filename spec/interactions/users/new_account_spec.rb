# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::NewAccount do
  let(:user) { FactoryBot.create(:profile).user }
  let!(:social_user) { FactoryBot.create(:social_user, user: user) }
  let(:args) do
    {
      existing_user: user
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a new user, profile and shop" do
      expect {
        outcome
      }.to change {
        User.count
      }.and change {
        Profile.count
      }.and change {
        Staff.count
      }.and change {
        StaffAccount.count
      }.and change {
        Shop.count
      }
    end
  end
end
