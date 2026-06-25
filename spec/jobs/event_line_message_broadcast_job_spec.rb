# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventLineMessageBroadcastJob do
  describe "#perform" do
    let(:event) { create(:event) }
    let(:client) { double("LineClient") }
    let(:broadcast) { create(:event_line_message_broadcast, event: event, message: "一括配信テスト") }
    let!(:registered_line_user) { create(:event_line_user, line_user_id: "Uregistered") }
    let!(:unregistered_line_user) { create(:event_line_user, line_user_id: "Uunregistered") }

    before do
      create(:event_participant, event: event, event_line_user: registered_line_user)
      allow(UserBotSocialAccount).to receive(:client).and_return(client)
      allow(client).to receive(:push_message)
    end

    it "sends the broadcast to registered event participants only" do
      described_class.perform_now(broadcast)

      expect(client).to have_received(:push_message).once.with(
        "Uregistered",
        { type: "text", text: "一括配信テスト" }
      )
      expect(client).not_to have_received(:push_message).with(
        "Uunregistered",
        anything
      )

      broadcast.reload
      expect(broadcast).to be_status_delivered
      expect(broadcast.delivered_count).to eq(1)
      expect(broadcast.failed_count).to eq(0)
      expect(broadcast.event_line_message_broadcast_deliveries.where(event_line_user: registered_line_user, sent_at: nil)).to be_empty
    end
  end
end
