# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::Notifications::NewReferrer, :with_line do
  let(:referral) { FactoryBot.create(:referral) }
  let(:referee) { referral.referee }

  let(:args) do
    {
      user: referee,
      receiver: referee
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when referee got social user" do
      before { FactoryBot.create(:social_user, user: referee) }

      it "sends line" do
        expect(LineClient).to receive(:send).with(referee.social_user, I18n.t("notifier.notifications.new_referrer.message", user_name: referee.name).strip)

        expect {
          outcome
        }.to change {
          SocialUserMessage.where(
            social_user: referee.social_user,
            raw_content: I18n.t("notifier.notifications.new_referrer.message", user_name: referee.name).strip
          ).count
        }.by(1)
      end
    end

    context "when referee got phone_number" do
      before { referee.update_columns(phone_number: Faker::PhoneNumber.phone_number) }

      it "sends sms" do
        expect {
          outcome
        }.to change {
          Notification.where(
            user: referee,
            content: I18n.t("notifier.notifications.new_referrer.message", user_name: referee.name).strip
          ).count
        }.by(1)
      end
    end

    context "when referee got email" do
      before { referee.update_columns(email: "foo@email.com", phone_number: nil) }

      it "sends email" do
        mailer_double = double(deliver_now: true)
        expect(UserMailer).to receive(:with).with(
          hash_including(
            email: anything,
            message: anything,
            subject: I18n.t("user_mailer.custom.title")
          )
        ).and_return(double(custom: mailer_double))

        outcome
      end
    end

    context "when referee got both sms and email" do
      before do
        referee.update_columns(phone_number: Faker::PhoneNumber.phone_number, email: "foo@email.com")
      end

      it "only sends sms" do
        expect(UserMailer).not_to receive(:with)

        expect {
          outcome
        }.to change {
          Notification.where(user: referee).count
        }.by(1)
      end
    end
  end
end
