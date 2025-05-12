# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::CustomMessages::Send, :with_line do
  let(:receiver) { FactoryBot.create(:social_user).user }
  let(:custom_message) { FactoryBot.create(:custom_message, :user_signed_up_scenario) }
  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, receiver.message_template_variables)
      expect(LineClient).to receive(:send).with(receiver.social_user, content)
      expect(CustomMessages::Users::Next).to receive(:run).with({
        custom_message: custom_message,
        receiver: receiver
      })

      expect {
        outcome
      }.to change {
        SocialUserMessage.where(
          social_user: receiver.social_user,
          raw_content: content,
          scenario: custom_message.scenario,
          nth_time: custom_message.nth_time
        ).count
      }.by(1)
    end

    # ::CustomMessages::Users::Template::NO_LINE_SETTINGS
    context "when scenario is no_line_settings but user already finished verification" do
      # For user line_settings_verified START
      let(:custom_message) { FactoryBot.create(:custom_message, :no_line_settings) }
      let!(:social_account) { FactoryBot.create(:social_account, user: receiver) }
      let(:owner_social_customer) { FactoryBot.create(:social_customer, :is_owner, user: receiver, social_account: receiver.social_account) }
      before do
        SocialMessages::Create.run(
          social_customer: owner_social_customer,
          content: receiver.social_user.social_service_user_id,
          readed: true, message_type:
          SocialMessage.message_types[:customer],
          send_line: false
        )
      end
      # For user line_settings_verified END

      it "does NOT sends line" do
        expect {
          outcome
        }.to not_change {
          SocialUserMessage.where(
            social_user: receiver.social_user,
            scenario: custom_message.scenario,
            nth_time: custom_message.nth_time
          ).count
        }
      end
    end

    context "when user received the same custom message before" do
      before do
        FactoryBot.create(
          :social_user_message,
          social_user: receiver.social_user,
          custom_message_id: custom_message.id,
          scenario: custom_message.scenario,
          nth_time: custom_message.nth_time
        )
      end

      it "does NOT deliver again" do
        expect {
          outcome
        }.not_to change {
          SocialUserMessage.where(
            social_user: receiver.social_user,
            scenario: custom_message.scenario,
            nth_time: custom_message.nth_time
          ).count
        }
      end
    end

    context "when send line failed" do
      let(:response_body) { { "message": "Send message failed" }.to_json }
      let(:response){ instance_double(Net::HTTPResponse, code: "400", body: response_body)}
      before { allow(LineClient).to receive(:send).and_return(response) }

      it "doesn't change receiver_ids list" do
        expect {
          outcome
        }.to change {
          SocialUserMessage.where(
            social_user: receiver.social_user,
          ).count
        }.by(1)
      end
    end

    context "custom message is flex type" do
      let(:custom_message) do
        FactoryBot.create(
          :custom_message,
          :user_signed_up_scenario,
          :flex,
          flex_template: "video_description_card",
          content: { title: "title", picture_url: ContentHelper::VIDEO_THUMBNAIL_URL, content_url: ContentHelper::VIDEO_THUMBNAIL_URL, context: "context" }.to_json
        )
      end

      it "sends flex message" do
        expect(LineClient).to receive(:flex)
        expect {
          outcome
        }.to change {
          SocialUserMessage.where(
            social_user: receiver.social_user,
            raw_content: CustomMessages::ReceiverContent.run!(custom_message: custom_message, receiver: receiver)
          ).count
        }.by(1)
      end
    end

    context 'when custom_message changed after_days' do
      it 'only send the latest scheduled message' do
        # CustomMessages::Users::Template::USER_SIGN_UP scenario
        scenario_start_at = receiver.created_at
        legacy_schedule_at = scenario_start_at.advance(days: custom_message.after_days).change(hour: 9)
        described_class.perform_at(schedule_at: legacy_schedule_at, scenario_start_at: scenario_start_at, receiver: receiver, custom_message: custom_message)

        custom_message.update(after_days: 999)

        new_schedule_at = scenario_start_at.advance(days: custom_message.after_days).change(hour: 9)
        described_class.perform_at(schedule_at: new_schedule_at, scenario_start_at: scenario_start_at, receiver: receiver, custom_message: custom_message)

        expect(CustomMessages::ReceiverContent).to receive(:run) do |args|
          expect(args[:custom_message].after_days).to eq(999)
        end.once.and_call_original

        perform_enqueued_jobs
      end
    end
  end
end
