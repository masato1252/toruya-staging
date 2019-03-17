require "rails_helper"

RSpec.describe StaffAccounts::CreateUser do
  let(:token) { staff_account.token }
  let(:args) do
    {
      token: token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when it is an invalid token" do
      let(:staff_account) { FactoryBot.create(:staff_account) }
      let(:token) { SecureRandom.hex }

      it "adds an error" do
        expect(outcome.errors.details[:base]).to include(error: "token was invalid")
      end
    end

    context "when the staff account already binded to a user" do
      let(:staff_account) { FactoryBot.create(:staff_account, :pending) }

      it "activates the user" do
        outcome

        staff_account.reload
        expect(staff_account).to be_active
        expect(staff_account.active_uniqueness).to eq(true)
        expect(outcome.result).to eq({ user: staff_account.user, owner: staff_account.owner })
      end
    end

    context "when the staff account doesn't binding a user" do
      let(:staff_account) { FactoryBot.create(:staff_account, user: nil) }

      it "creates a user and activates it" do
        expect(staff_account.user).to eq(nil)
        outcome

        staff_account.reload
        expect(staff_account.user).to eq(User.find_by(email: staff_account.email))
        expect(staff_account).to be_active
        expect(staff_account.active_uniqueness).to eq(true)
      end
    end
  end
end
