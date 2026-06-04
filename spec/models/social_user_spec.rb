# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialUser do
  describe ".linked_for_line" do
    let(:line_id) { "U_test_linked_for_line" }

    it "returns the linked row when an evacuated row exists on the same LINE" do
      evacuated = described_class.create!(
        social_service_user_id: line_id,
        user_id: nil,
        social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY
      )
      linked = described_class.create!(
        social_service_user_id: line_id,
        user_id: 1028,
        social_rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )

      expect(described_class.linked_for_line(line_id)).to eq(linked)
      expect(described_class.linked_for_line(line_id).id).not_to eq(evacuated.id)
    end

    it "returns nil when only a guest row exists" do
      guest = described_class.create!(
        social_service_user_id: line_id,
        user_id: nil,
        social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY
      )

      expect(described_class.linked_for_line(line_id)).to be_nil
      expect(guest.user_id).to be_nil
    end
  end

  describe "#toruya_user_id" do
    let(:line_id) { "U_test_toruya_user_id" }

    it "falls back to root_user when the row is evacuated" do
      described_class.create!(
        social_service_user_id: line_id,
        user_id: nil,
        social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY
      )
      described_class.create!(
        social_service_user_id: line_id,
        user_id: 1028,
        social_rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )
      evacuated = described_class.order(:id).find_by!(social_service_user_id: line_id, user_id: nil)

      expect(evacuated.toruya_user_id).to eq(1028)
    end
  end
end
