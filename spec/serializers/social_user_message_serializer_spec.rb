# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialUserMessageSerializer do
  let(:social_user) { FactoryBot.create(:social_user) }

  describe "#attributes_hash" do
    it "serializes a plain text message without error" do
      message = FactoryBot.create(
        :social_user_message,
        social_user: social_user,
        raw_content: "hello from user",
        content_type: SocialUserMessages::Create::TEXT_TYPE,
        message_type: SocialUserMessage.message_types[:user]
      )

      hash = described_class.new(message).attributes_hash

      expect(hash[:text]).to eq("hello from user")
      expect(hash[:is_image]).to eq(false)
      expect(hash[:is_video]).to eq(false)
    end

    it "serializes an image message" do
      message = FactoryBot.create(
        :social_user_message,
        social_user: social_user,
        raw_content: { previewImageUrl: "https://example.com/p.jpg" }.to_json,
        content_type: SocialUserMessages::Create::IMAGE_TYPE,
        message_type: SocialUserMessage.message_types[:user]
      )

      hash = described_class.new(message).attributes_hash

      expect(hash[:is_image]).to eq(true)
      expect(hash[:is_video]).to eq(false)
    end
  end
end
