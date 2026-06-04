# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialUsers::Initialize do
  describe "#execute" do
    let(:line_id) { "U_test_initialize_linked" }

    it "returns the linked social_user instead of the evacuated guest row" do
      described_class.create!(
        social_service_user_id: line_id,
        user_id: nil,
        social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY
      )
      linked = described_class.create!(
        social_service_user_id: line_id,
        user_id: 1028,
        social_rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )

      result = described_class.run!(social_service_user_id: line_id, who: CallbacksController::TORUYA_USER)

      expect(result).to eq(linked)
      expect(result.user_id).to eq(1028)
    end
  end
end
