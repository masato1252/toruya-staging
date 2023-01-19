# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::Notifications::ActivateStaffAccount, :with_line do
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
            content: I18n.t(
              "notifier.notifications.activate_staff_account.message",
              user_name: receiver.owner.name,
              url: Rails.application.routes.url_helpers.lines_user_bot_line_sign_up_url(staff_token: receiver.token)
            )
          ).count
        }.by(1)
      end
    end
  end
end
