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
          raw_content: content
        ).count
      }.by(1)

      expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
    end

    context "when send line failed" do
      before { allow(LineClient).to receive(:send).and_return(Net::HTTPResponse.new(1.0, "400", "BAD_REQUEST")) }

      it "doesn't change receiver_ids list" do
        expect {
          outcome
        }.to change {
          SocialUserMessage.where(
            social_user: receiver.social_user
          ).count
        }.by(1)

        expect(custom_message.receiver_ids).to eq([])
      end
    end

    context "when this custom message was ever sent before" do
      let(:custom_message) { FactoryBot.create(:custom_message, receiver_ids: [receiver.id]) }

      it "doesn't send line but still schedule next message" do
        expect(CustomMessages::Users::Next).to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialUserMessage.where(social_user: receiver.social_user).count
        }

        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
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
