# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::RegisterParticipant do
  let(:event) { FactoryBot.create(:event, :during_event) }
  let(:shop) { FactoryBot.create(:shop) }
  let!(:booth) { FactoryBot.create(:event_content, :published, :booth, event: event, shop: shop) }
  let(:event_line_user) { FactoryBot.create(:event_line_user) }

  def run_register(**overrides)
    described_class.run!(
      {
        event: event,
        event_line_user: event_line_user,
        business_types: ["セラピスト"],
        business_age: "under_one_year",
        concern_labels: ["新規のお客様がなかなか増えない"],
        first_name: "太郎",
        last_name: "山田",
        phone_number: "09012345678",
        email: "taro@example.com"
      }.merge(overrides)
    )
  end

  it "stores referrer_event_content_id for booth registrations" do
    participant = run_register(referrer_event_content_id: booth.id)

    expect(participant.referrer_event_content_id).to eq(booth.id)
  end

  it "ignores invalid referrer_event_content_id" do
    other_event = FactoryBot.create(:event, :during_event)
    other_booth = FactoryBot.create(:event_content, :published, :booth, event: other_event)

    participant = run_register(referrer_event_content_id: other_booth.id)

    expect(participant.referrer_event_content_id).to be_nil
  end

  it "ignores seminar content as referrer_event_content_id" do
    seminar = FactoryBot.create(:event_content, :published, event: event)

    participant = run_register(referrer_event_content_id: seminar.id)

    expect(participant.referrer_event_content_id).to be_nil
  end
end
