# frozen_string_literal: true

require "rails_helper"
require "sms_client"

RSpec.describe Sms::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:reservation) { FactoryBot.create(:reservation) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:message) { "foo" }

  let(:args) do
    {
      user: user,
      customer: customer,
      reservation: reservation,
      phone_number: phone_number,
      message: message
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    # Mock Rails.env for SayHi concern
    allow(Rails.configuration.x).to receive(:env).and_return(double(production?: false))
  end

  describe "#execute" do
    context "when successful" do
      before do
        allow(SmsClient).to receive(:send).and_return(true)
      end

      it "calls SmsClient with correct locale" do
        expect(SmsClient).to receive(:send).with(phone_number, message, user.locale)
        outcome
      end

      context "when customer exists" do
        it "creates a SocialMessage without social associations" do
          expect {
            outcome
          }.to change {
            SocialMessage.where(
              social_account: nil,
              social_customer: nil,
              customer_id: customer.id,
              user_id: customer.user_id,
              raw_content: message,
              content_type: "text",
              message_type: "bot",
              channel: "sms"
            ).count
          }.by(1)

          social_message = SocialMessage.last
          expect(social_message.readed_at).to be_present
          expect(social_message.sent_at).to be_present
        end

        context "with social associations" do
          let(:social_account) { FactoryBot.create(:social_account, user: user) }
          let(:social_customer) { FactoryBot.create(:social_customer, user: user, social_account: social_account, customer: customer) }

          before do
            customer.update!(social_customer: social_customer)
          end

          it "creates a SocialMessage with social associations" do
            expect {
              outcome
            }.to change {
              SocialMessage.where(
                social_account: social_account,
                social_customer: social_customer,
                customer_id: customer.id,
                user_id: customer.user_id,
                raw_content: message,
                content_type: "text",
                message_type: "bot",
                channel: "sms"
              ).count
            }.by(1)

            social_message = SocialMessage.last
            expect(social_message.readed_at).to be_present
            expect(social_message.sent_at).to be_present
          end
        end
      end

      it "creates a Notification with all associations" do
        expect {
          outcome
        }.to change {
          Notification.where(
            user: user,
            phone_number: phone_number,
            content: message,
            customer_id: customer.id,
            reservation_id: reservation.id
          ).count
        }.by(1)
      end
    end

    context "when SMS client raises an error" do
      let(:twilio_error) { Class.new(StandardError).new("error message") }

      before do
        stub_const("Twilio::REST::RestError", Class.new(StandardError))
        allow(SmsClient).to receive(:send).and_raise(Twilio::REST::RestError.new("error message"))
      end

      it "reports error to Rollbar with context" do
        expect(Rollbar).to receive(:error).with(
          kind_of(Twilio::REST::RestError),
          phone_numbers: phone_number,
          user_id: user&.id,
          customer_id: customer&.id,
          reservation_id: reservation&.id,
          rails_env: Rails.configuration.x.env
        )

        outcome
      end

      it "does not raise the error" do
        expect { outcome }.not_to raise_error
      end
    end

    context "when no user or customer provided" do
      let(:args) do
        {
          phone_number: phone_number,
          message: message
        }
      end

      before do
        allow(SmsClient).to receive(:send).and_return(true)
      end

      it "calls SmsClient with default locale" do
        expect(SmsClient).to receive(:send).with(phone_number, message, "ja")
        outcome
      end

      it "creates a Notification without associations" do
        expect {
          outcome
        }.to change {
          Notification.where(
            user: nil,
            phone_number: phone_number,
            content: message,
            customer_id: nil,
            reservation_id: nil
          ).count
        }.by(1)
      end
    end
  end
end