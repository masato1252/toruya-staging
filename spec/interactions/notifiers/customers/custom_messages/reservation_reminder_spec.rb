# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::CustomMessages::ReservationReminder, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:custom_message) { FactoryBot.create(:custom_message, service: booking_page, before_minutes: 10) }
  let(:relation) { FactoryBot.create(:reservation_customer, booking_page: booking_page) }
  let(:reservation) { relation.reservation }
  let(:booking_page) { FactoryBot.create(:booking_page) }
  before do
    # Make reservation and customer able to remind
    reservation.accept!
    relation.accepted!
    receiver.update(reminder_permission: true)
  end
  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message,
      reservation: reservation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, custom_message.service.message_template_variables(receiver))

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: content
        ).count
      }.by(1)
    end

    context 'when custom_message changed before_minutes' do
      it 'only send the latest scheduled message' do
        legacy_schedule_at = reservation.start_time.advance(minutes: -custom_message.before_minutes)
        described_class.perform_at(schedule_at: legacy_schedule_at, receiver: receiver, custom_message: custom_message, reservation: reservation)

        custom_message.update(before_minutes: 20)

        new_schedule_at = reservation.start_time.advance(minutes: -custom_message.before_minutes)
        described_class.perform_at(schedule_at: new_schedule_at, receiver: receiver, custom_message: custom_message, reservation: reservation)

        expect(CustomMessages::ReceiverContent).to receive(:run) do |args|
          expect(args[:custom_message].before_minutes).to eq(20)
        end.once.and_call_original

        perform_enqueued_jobs
      end
    end
  end
end
