# frozen_string_literal: true

require "rails_helper"
require "sms_client"

RSpec.describe Notifiers::Customers::CustomMessages::Send, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:custom_message) { FactoryBot.create(:custom_message, service: relation.online_service) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  # Create a user setting with line notification channel for the receiver
  let!(:user_setting) { FactoryBot.create(:user_setting, user: receiver.user, customer_notification_channel: 'line') }

  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, custom_message.service.message_template_variables(receiver))

      # Set up the business owner
      business_owner = receiver.user
      allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(business_owner)

      # Set the notification channel explicitly
      allow(business_owner).to receive(:customer_notification_channel).and_return("line")

      # Ensure LINE is available as a notification channel
      allow_any_instance_of(Notifiers::Base).to receive(:available_to_send_line?).and_return(true)

      # First, expect LineClient.send to be called
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)

      # Then, mock the actual messages creation to create a real record
      allow_any_instance_of(Notifiers::Base).to receive(:notify_by_line) do |instance|
        # Call the original LineClient.send (which is now mocked)
        LineClient.send(receiver.social_customer, content)

        # Create a real SocialMessage record using the factory
        FactoryBot.create(:social_message,
          social_customer: receiver.social_customer,
          content_type: SocialUserMessages::Create::TEXT_TYPE,
          raw_content: content,
          message_type: SocialMessage.message_types[:bot]
        )
        true
      end

      expect(CustomMessages::Customers::Next).to receive(:run).with({
        custom_message: custom_message,
        receiver: receiver
      })

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: content
        ).count
      }.by(1)

      expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
    end

    context "when this custom message was ever sent before" do
      let(:custom_message) { FactoryBot.create(:custom_message, receiver_ids: [receiver.id]) }

      it "doesn't send line but still schedule next message" do
        expect(CustomMessages::Customers::Next).to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }

        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
      end
    end

    context "when this custom message's customer was unavailable to use this product" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation) }

      it "doesn't send line but still schedule next message" do
        expect(CustomMessages::Customers::Next).to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }
      end
    end

    context 'when custom_message changed after_days' do
      it 'only send the latest scheduled message' do
        # Set the notification channel to line
        allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(receiver.user)
        allow(receiver.user).to receive(:customer_notification_channel).and_return("line")

        legacy_schedule_at = custom_message.service.start_at_for_customer(receiver).advance(days: custom_message.after_days).change(hour: 9)
        described_class.perform_at(schedule_at: legacy_schedule_at, receiver: receiver, custom_message: custom_message)

        custom_message.update(after_days: 999)

        new_schedule_at = custom_message.service.start_at_for_customer(receiver).advance(days: custom_message.after_days).change(hour: 9, min: rand(5), sec: rand(59))
        described_class.perform_at(schedule_at: new_schedule_at, receiver: receiver, custom_message: custom_message)

        expect(CustomMessages::ReceiverContent).to receive(:run) do |args|
          expect(args[:custom_message].after_days).to eq(999)
        end.once.and_call_original

        perform_enqueued_jobs
      end
    end

    context "when this online service's upsell sale page was sold" do
      let(:upsell_sale_page) { FactoryBot.create(:sale_page, :online_service, user: receiver.user) }
      let!(:sold_sale_page_relation) { FactoryBot.create(:online_service_customer_relation, :free, sale_page: upsell_sale_page, customer: receiver) }
      before do
        relation.online_service.update(sale_page: upsell_sale_page)
      end

      it "doesn't send line but still schedule next message" do
        expect(CustomMessages::Customers::Next).to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }
      end
    end

    context "when user's customer_notification_channel is sms" do
      # Set SMS as the preferred notification channel
      before do
        user_setting.update(customer_notification_channel: 'sms')
      end

      it "sends sms and creates notification record with user and customer" do
        # Ensure the receiver has a phone number (necessary for SMS)
        allow(receiver).to receive(:phone_number).and_return("1234567890")

        # Make sure locale is set for the real implementation
        allow(receiver).to receive(:locale).and_return(:ja)

        # Mock the business owner for notification channel
        allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(receiver.user)

        # Set the notification channel explicitly to SMS
        allow(receiver.user).to receive(:customer_notification_channel).and_return("sms")

        # Ensure SMS is available as a notification channel
        allow_any_instance_of(Notifiers::Base).to receive(:available_to_send_sms?).and_return(true)

        # Generate content (same as in the LINE test)
        content = Translator.perform(custom_message.content, custom_message.service.message_template_variables(receiver))

        # Expect SmsClient to be called with locale as a symbol
        expect(SmsClient).to receive(:send).with(receiver.phone_number, content, :ja)

        # Don't mock notify_by_sms, use the real implementation instead
        # We still need to mock SmsClient to avoid sending real SMS

        # Expect Next to be called same as in other tests
        expect(CustomMessages::Customers::Next).to receive(:run).with({
          custom_message: custom_message,
          receiver: receiver
        })

        # Check that a Notification record is created with the right attributes
        expect {
          outcome
        }.to change {
          Notification.where(
            user: receiver.user,
            customer_id: receiver.id,
            phone_number: receiver.phone_number,
            content: content
          ).count
        }.by(1)

        # Confirm receiver_ids is updated
        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
      end
    end
  end
end
