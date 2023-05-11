# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaffAccounts::Create do
  let(:staff) { FactoryBot.create(:staff, :without_staff_account) }
  let(:level) { "employee" }
  let(:phone_number) { "123456" }
  let(:params) do
    {
      phone_number: phone_number,
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
    context "when there is an existing active staff use the same phone number for its staff account" do
      let(:existing_staff) { FactoryBot.create(:staff) }
      let(:staff) { FactoryBot.create(:staff, :without_staff_account, user: existing_staff.user) }
      let(:params) do
        {
          phone_number: existing_staff.staff_account.phone_number,
          level: "employee"
        }.with_indifferent_access
      end

      it "adds an error" do
        expect(outcome.errors.details[:staff]).to include(error: :phone_number_uniqueness_required)
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
          allow(Sms::Create).to receive(:run).and_return(spy)
          outcome

          expect(staff.staff_account.user).to eq(nil)
          expect(staff.staff_account).to be_pending
          expect(staff.staff_account.active_uniqueness).to eq(nil)
          expect(Sms::Create).to have_received(:run)
        end
      end

      context "when there is a existing user's phone_number is the same as the new phone_number" do
        let!(:existing_user) { FactoryBot.create(:user, phone_number: Phonelib.parse(phone_number, :jp).international(false)) }

        it "bind the existing user to staff" do
          allow(Sms::Create).to receive(:run).and_return(spy)
          outcome

          expect(staff.staff_account.user).to eq(existing_user)
          expect(Sms::Create).to have_received(:run)
        end
      end
    end
  end
end
