# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaffAccounts::Create do
  let(:staff) { FactoryBot.create(:staff, :without_staff_account) }
  let(:level) { "employee" }
  let(:email) { "foo@email.com" }
  let(:params) do
    {
      email: email,
      level: "employee"
    }.with_indifferent_access
  end
  let(:args) do
    {
      staff: staff,
      params: params,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is an existing active staff use the same email for its staff account" do
      let(:existing_staff) { FactoryBot.create(:staff) }
      let(:staff) { FactoryBot.create(:staff, :without_staff_account, user: existing_staff.user) }
      let(:params) do
        {
          email: existing_staff.staff_account.email,
          level: "employee"
        }.with_indifferent_access
      end

      it "adds an error" do
        expect(outcome.errors.details[:staff]).to include(error: :email_uniqueness_required)
      end
    end

    context "when existing staff want to change its staff account upgrade to/downgrade from owner" do
      context "upgrade to owner" do
        let(:staff) { FactoryBot.create(:staff) }
        it "adds an error" do
          params.merge!(level: "owner")

          expect(outcome.errors.details[:level]).to include(error: "You could not change owner level")
        end
      end

      context "downgrade from owner" do
        let(:staff) { FactoryBot.create(:staff, :owner) }

        it "adds an error" do
          expect(outcome.errors.details[:level]).to include(error: "You could not change owner level")
        end
      end
    end

    context "when staff_account email changed(new staff account/existing account changed email)" do
      context "when it is a owner staff account" do
        it "is active directly" do
          params.merge!(level: "owner")
          outcome

          expect(staff.staff_account).to be_active
          expect(staff.staff_account.active_uniqueness).to eq(true)
        end
      end

      context "when it is a employee staff account" do
        it "sends the activate_staff_account email and mark staff account pending" do
          allow(NotificationMailer).to receive(:activate_staff_account).and_return(spy)
          outcome

          expect(staff.staff_account.user).to eq(nil)
          expect(staff.staff_account).to be_pending
          expect(staff.staff_account.active_uniqueness).to eq(nil)
          expect(NotificationMailer).to have_received(:activate_staff_account)
        end
      end

      context "when there is a existing user's email is the same as the new email" do
        let!(:existing_user) { FactoryBot.create(:user, email: email) }

        it "bind the existing user to staff" do
          allow(NotificationMailer).to receive(:activate_staff_account).and_return(spy)
          outcome

          expect(staff.staff_account.user).to eq(existing_user)
          expect(NotificationMailer).to have_received(:activate_staff_account)
        end
      end
    end
  end
end
