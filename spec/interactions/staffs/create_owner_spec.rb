require "rails_helper"

RSpec.describe Staffs::CreateOwner do
  let(:profile) { FactoryBot.create(:profile) }
  let(:user) { profile.user }
  let(:args) do
    {
      user: user
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when user's itself staff account exists" do
      let(:staff_account) { FactoryBot.create(:staff_account, user: user, owner: user, level: "employee") }

      context "when user's staff account is not owner level" do
        it "change it to owner level" do
          expect(staff_account).not_to be_owner

          outcome
          staff_account.reload

          expect(staff_account).to be_owner
        end
      end
    end

    context "when user doesn't have a staff account" do
      it "creates a owner level staff account" do
        outcome

        staff_account = user.current_staff_account(user)
        expect(staff_account).to be_owner
      end
    end
  end
end
