# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::CustomMessages::Send, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:custom_message) { FactoryBot.create(:custom_message, service: relation.online_service) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
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
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)
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
        legacy_schedule_at = custom_message.service.start_at_for_customer(receiver).advance(days: custom_message.after_days).change(hour: 9)
        described_class.perform_at(schedule_at: legacy_schedule_at, receiver: receiver, custom_message: custom_message)

        custom_message.update(after_days: 999)

        new_schedule_at = custom_message.service.start_at_for_customer(receiver).advance(days: custom_message.after_days).change(hour: 9)
        described_class.perform_at(schedule_at: new_schedule_at, receiver: receiver, custom_message: custom_message)

        expect(CustomMessages::ReceiverContent).to receive(:run) do |args|
          expect(args[:custom_message].after_days).to eq(999)
        end.once.and_call_original

        perform_enqueued_jobs
      end
    end
  end
end
