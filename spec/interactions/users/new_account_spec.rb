# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::NewAccount do
  let(:user) { FactoryBot.create(:profile).user }
  let(:social_user) { FactoryBot.create(:social_user, user: user) }
  let(:args) do
    {
      existing_user: user,
      social_user: social_user
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
      }

      new_user = User.last
      new_staff = new_user.current_staff(user)
      new_staff_account = user.owner_staff_accounts.where(owner_id: user.id, staff_id: new_staff.id).last

      expect(new_staff_account).to be_owner
      expect(new_staff_account).to be_active
    end
  end
end
