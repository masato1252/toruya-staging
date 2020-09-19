require "rails_helper"

RSpec.describe Notifiers::ActivateStaffAccount do
  let(:user) { receiver.owner }

  let(:args) do
    {
      user: user,
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when staff account got phone_number" do
      let(:receiver) { FactoryBot.create(:staff_account, :phone_number) }

      it "sends sms" do
        expect {
          outcome
        }.to change {
          Notification.where(
            user: user,
            content: I18n.t("notifier.activate_staff_account.message", url: url_helpers.user_from_callbacks_staff_accounts_url(token: receiver.token))
          ).count
        }.by(1)
      end
    end

    context "when staff account got email" do
      let(:receiver) { FactoryBot.create(:staff_account, :email) }

      it "sends email" do
        expect(NotificationMailer).to receive(:activate_staff_account).with(receiver).and_return(double(deliver_now: true))

        outcome
      end
    end

    context "when staff account got both sms and email" do
      let(:receiver) { FactoryBot.create(:staff_account, :email, :phone_number) }

      it "only sends sms" do
        expect(NotificationMailer).not_to receive(:activate_staff_account)

        expect {
          outcome
        }.to change {
          Notification.where(user: user).count
        }.by(1)
      end
    end
  end
end
