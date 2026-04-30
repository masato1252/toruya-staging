# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model do
  # 旧仕様では「開催前のみプレビュー可能」だったが、現仕様ではタイミングに関わらず
  # 「下書き(status=0)コンテンツの可視化権限」としてプレビュー機能を提供する。
  describe "#master_previewer?" do
    let(:owner_user) { FactoryBot.create(:user) }
    let(:master_shop) { FactoryBot.create(:shop, user: owner_user) }
    let(:line_user) { FactoryBot.create(:event_line_user, toruya_user_id: owner_user.id) }

    context "when event has not started yet" do
      let(:event) { FactoryBot.create(:event, :pre_event, master_preview_shop: master_shop) }

      it "returns true for the master_preview_shop owner" do
        expect(event.master_previewer?(line_user)).to be true
      end
    end

    context "when event is currently running (started, not ended)" do
      let(:event) { FactoryBot.create(:event, :during_event, master_preview_shop: master_shop) }

      it "still returns true for the master_preview_shop owner (no longer pre-event-limited)" do
        expect(event.master_previewer?(line_user)).to be true
      end
    end

    context "when event has ended" do
      let(:event) { FactoryBot.create(:event, :ended, master_preview_shop: master_shop) }

      it "still returns true for the master_preview_shop owner" do
        expect(event.master_previewer?(line_user)).to be true
      end
    end

    context "when line_user is unrelated to the master_preview_shop" do
      let(:event) { FactoryBot.create(:event, :pre_event, master_preview_shop: master_shop) }
      let(:other_user) { FactoryBot.create(:user) }
      let(:other_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: other_user.id) }

      it "returns false" do
        expect(event.master_previewer?(other_line_user)).to be false
      end
    end

    context "when line_user has no toruya_user_id" do
      let(:event) { FactoryBot.create(:event, :pre_event, master_preview_shop: master_shop) }
      let(:anon_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: nil) }

      it "returns false" do
        expect(event.master_previewer?(anon_line_user)).to be false
      end
    end

    context "when master_preview_shop is not configured" do
      let(:event) { FactoryBot.create(:event, :pre_event, master_preview_shop: nil) }

      it "returns false" do
        expect(event.master_previewer?(line_user)).to be false
      end
    end
  end

  describe "#previewable_content_ids_for" do
    let(:exhibitor_user) { FactoryBot.create(:user) }
    let(:exhibitor_shop) { FactoryBot.create(:shop, user: exhibitor_user) }
    let(:line_user) { FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_user.id) }
    let(:event) { FactoryBot.create(:event, :during_event) }

    it "returns the exhibitor shop's UNPUBLISHED content ids regardless of event timing" do
      draft = FactoryBot.create(:event_content, :unpublished, event: event, shop: exhibitor_shop)
      FactoryBot.create(:event_content, :published, event: event, shop: exhibitor_shop)

      expect(event.previewable_content_ids_for(line_user)).to contain_exactly(draft.id)
    end

    it "does NOT include drafts of OTHER shops" do
      other_shop = FactoryBot.create(:shop)
      FactoryBot.create(:event_content, :unpublished, event: event, shop: other_shop)

      expect(event.previewable_content_ids_for(line_user)).to be_empty
    end

    it "returns [] when line_user has no toruya_user_id" do
      anon_line_user = FactoryBot.create(:event_line_user, toruya_user_id: nil)
      FactoryBot.create(:event_content, :unpublished, event: event, shop: exhibitor_shop)

      expect(event.previewable_content_ids_for(anon_line_user)).to eq([])
    end
  end

  describe "#visible_event_contents_for" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let!(:public_content) { FactoryBot.create(:event_content, :published, event: event) }

    let(:exhibitor_user) { FactoryBot.create(:user) }
    let(:exhibitor_shop) { FactoryBot.create(:shop, user: exhibitor_user) }
    let!(:exhibitor_draft) { FactoryBot.create(:event_content, :unpublished, event: event, shop: exhibitor_shop) }

    let(:other_shop) { FactoryBot.create(:shop) }
    let!(:other_draft) { FactoryBot.create(:event_content, :unpublished, event: event, shop: other_shop) }

    context "when viewer is unauthenticated (line_user is nil)" do
      it "returns only published contents" do
        expect(event.visible_event_contents_for(nil)).to contain_exactly(public_content)
      end
    end

    context "when viewer is a regular logged-in user (no shop affiliation)" do
      let(:plain_user) { FactoryBot.create(:user) }
      let(:plain_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: plain_user.id) }

      it "returns only published contents" do
        expect(event.visible_event_contents_for(plain_line_user)).to contain_exactly(public_content)
      end
    end

    context "when viewer is owner of an exhibitor shop" do
      let(:exhibitor_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_user.id) }

      it "returns published + own-shop drafts only" do
        expect(event.visible_event_contents_for(exhibitor_line_user))
          .to contain_exactly(public_content, exhibitor_draft)
      end
    end

    context "when viewer is owner of the master_preview_shop" do
      let(:master_user) { FactoryBot.create(:user) }
      let(:master_shop) { FactoryBot.create(:shop, user: master_user) }
      let(:master_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: master_user.id) }

      before { event.update!(master_preview_shop: master_shop) }

      it "returns ALL contents (published + every draft)" do
        expect(event.visible_event_contents_for(master_line_user))
          .to contain_exactly(public_content, exhibitor_draft, other_draft)
      end
    end
  end
end
