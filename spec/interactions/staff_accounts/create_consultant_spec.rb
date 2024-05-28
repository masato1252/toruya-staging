# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaffAccounts::CreateConsultant do
  let(:consultant) { FactoryBot.create(:profile).user }
  let(:client) { FactoryBot.create(:profile).user }
  let(:token) { consultant.referral_token }
  let(:args) do
    {
      token: token,
      client: client
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "create a staff account relation between client and consultant" do
      expect {
        outcome
      }.to change {
        Staff.count
      }.and change {
        StaffAccount.count
      }

      staff_account = StaffAccount.last
      expect(staff_account.owner).to eq(client)
      expect(staff_account.user).to eq(consultant)
      expect(staff_account).to be_active
      expect(staff_account.active_uniqueness).to eq(true)
    end
  end
end
