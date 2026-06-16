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

    context "when line_user is linked through the current SocialUser record" do
      let(:event) { FactoryBot.create(:event, :pre_event, master_preview_shop: master_shop) }
      let(:linked_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: nil) }

      before do
        FactoryBot.create(:social_user, social_service_user_id: linked_line_user.line_user_id, user: owner_user)
      end

      it "returns true even if event_line_users.toruya_user_id is stale" do
        expect(event.master_previewer?(linked_line_user)).to be true
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

    it "uses the current SocialUser link when event_line_users.toruya_user_id is missing" do
      linked_line_user = FactoryBot.create(:event_line_user, toruya_user_id: nil)
      draft = FactoryBot.create(:event_content, :unpublished, event: event, shop: exhibitor_shop)
      FactoryBot.create(:social_user, social_service_user_id: linked_line_user.line_user_id, user: exhibitor_user)

      expect(event.previewable_content_ids_for(linked_line_user)).to contain_exactly(draft.id)
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

    # Toruya 管理者は staffs.user_id が店舗オーナー、staff_accounts.user_id が個人ログイン。
    context "when viewer is admin staff (staff_account.user_id, not staffs.user_id)" do
      let(:owner_user) { exhibitor_user }
      let(:admin_user) { FactoryBot.create(:user) }
      let(:admin_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: admin_user.id) }
      let!(:admin_staff) do
        FactoryBot.create(
          :staff,
          user: owner_user,
          shop: exhibitor_shop,
          mapping_user: admin_user,
          level: :manager
        )
      end

      before do
        admin_staff # ensure shop_staff + staff_account exist
        exhibitor_draft # draft on exhibitor_shop
      end

      it "returns published + drafts for shops linked via staff_account" do
        expect(event.visible_event_contents_for(admin_line_user))
          .to contain_exactly(public_content, exhibitor_draft)
      end
    end

    context "when viewer is admin staff of master_preview_shop" do
      let(:master_owner) { FactoryBot.create(:user) }
      let(:master_shop) { FactoryBot.create(:shop, user: master_owner) }
      let(:admin_user) { FactoryBot.create(:user) }
      let(:admin_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: admin_user.id) }

      before do
        event.update!(master_preview_shop: master_shop)
        FactoryBot.create(:staff, user: master_owner, shop: master_shop, mapping_user: admin_user, level: :manager)
      end

      it "returns ALL contents via master_previewer?" do
        expect(event.master_previewer?(admin_line_user)).to be true
        expect(event.visible_event_contents_for(admin_line_user))
          .to contain_exactly(public_content, exhibitor_draft, other_draft)
      end
    end
  end

  describe "#analytics_excluded_event_line_user_ids and #shop_acquisition_counts" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let(:exhibitor_shop) { FactoryBot.create(:shop) }
    let(:exhibitor_user) { exhibitor_shop.user }
    let!(:booth_content) { FactoryBot.create(:event_content, :unpublished, :booth, event: event, shop: exhibitor_shop) }

    let(:insider_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_user.id) }
    let(:public_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: FactoryBot.create(:user).id) }

    before do
      FactoryBot.create(
        :event_participant,
        event: event,
        event_line_user: insider_line_user,
        referrer_shop_id: exhibitor_shop.id
      )
      FactoryBot.create(
        :event_participant,
        event: event,
        event_line_user: public_line_user,
        referrer_shop_id: exhibitor_shop.id
      )
    end

    it "excludes preview insiders from acquisition counts" do
      expect(event.preview_insider?(insider_line_user)).to be true
      expect(event.preview_insider?(public_line_user)).to be false
      expect(event.analytics_excluded_event_line_user_ids).to contain_exactly(insider_line_user.id)

      counts = event.shop_acquisition_counts(exhibitor_shop.id)
      expect(counts[:direct]).to eq(1)
      expect(counts[:total]).to eq(1)
    end

    it "counts only non-insiders in analytics_participants_count" do
      expect(event.analytics_participants_count).to eq(1)
    end
  end

  describe "#admin_participant_rows and #admin_participant_count_breakdown" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let(:exhibitor_shop) { FactoryBot.create(:shop) }
    let!(:booth_content) { FactoryBot.create(:event_content, :unpublished, :booth, event: event, shop: exhibitor_shop) }

    let(:exhibitor_line_user) do
      FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_shop.user_id, first_name: "出展", last_name: "太郎",
                                         email: "exhibitor@example.com", phone_number: "09011112222")
    end
    let(:general_complete_line_user) do
      FactoryBot.create(:event_line_user, first_name: "一般", last_name: "花子",
                                         email: "general@example.com", phone_number: "09033334444")
    end
    let(:incomplete_line_user) do
      FactoryBot.create(:event_line_user, display_name: "未登録LINE", first_name: nil, last_name: nil)
    end

    before do
      FactoryBot.create(:event_participant, event: event, event_line_user: exhibitor_line_user)
      FactoryBot.create(:event_participant, event: event, event_line_user: general_complete_line_user)
      FactoryBot.create(:event_activity_log, event: event, event_line_user: incomplete_line_user,
                                             event_content: booth_content, activity_type: :seminar_view)
    end

    it "includes participants and activity-only users with incomplete profiles" do
      rows = event.admin_participant_rows
      expect(rows.map(&:event_line_user)).to contain_exactly(
        exhibitor_line_user, general_complete_line_user, incomplete_line_user
      )
      incomplete_row = rows.find { |r| r.event_line_user == incomplete_line_user }
      expect(incomplete_row.participant).to be_nil
      expect(incomplete_row.profile_complete).to be false
      expect(incomplete_line_user.admin_display_name).to eq("-")
    end

    it "breaks down counts by exhibitor role and profile completion" do
      breakdown = event.admin_participant_count_breakdown
      expect(breakdown[:general]).to eq(total: 2, profile_complete: 1, profile_incomplete: 1)
      expect(breakdown[:exhibitor]).to eq(total: 1, profile_complete: 1, profile_incomplete: 0)
    end

    it "classifies participants linked through SocialUser as exhibitors" do
      linked_line_user = FactoryBot.create(
        :event_line_user,
        toruya_user_id: nil,
        first_name: "連携",
        last_name: "出展者",
        email: "linked-exhibitor@example.com",
        phone_number: "09055556666"
      )
      FactoryBot.create(:social_user, social_service_user_id: linked_line_user.line_user_id, user: exhibitor_shop.user)
      FactoryBot.create(:event_participant, event: event, event_line_user: linked_line_user)

      row = event.admin_participant_rows.find { |participant_row| participant_row.event_line_user == linked_line_user }
      expect(row.exhibitor).to be true
    end

    it "classifies participants as exhibitors when a shop is linked after registration" do
      later_exhibitor_shop = FactoryBot.create(:shop)
      later_exhibitor_line_user = FactoryBot.create(
        :event_line_user,
        toruya_user_id: later_exhibitor_shop.user_id,
        first_name: "後付",
        last_name: "出展者",
        email: "later-exhibitor@example.com",
        phone_number: "09077778888"
      )
      FactoryBot.create(:event_participant, event: event, event_line_user: later_exhibitor_line_user)

      FactoryBot.create(:event_content, :published, event: event, shop: later_exhibitor_shop)

      row = event.admin_participant_rows.find { |participant_row| participant_row.event_line_user == later_exhibitor_line_user }
      expect(row.exhibitor).to be true
    end
  end

  describe "#admin_shop_acquisition_rows" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let(:shop) { FactoryBot.create(:shop) }
    let(:unlinked_shop) { FactoryBot.create(:shop) }
    let!(:content) { FactoryBot.create(:event_content, :unpublished, :booth, event: event, shop: shop) }

    let(:direct_line_user) { FactoryBot.create(:event_line_user) }
    let(:indirect_line_user) { FactoryBot.create(:event_line_user) }

    before do
      content
      FactoryBot.create(:event_participant, event: event, event_line_user: direct_line_user, referrer_shop_id: shop.id)
      FactoryBot.create(
        :event_participant,
        event: event,
        event_line_user: indirect_line_user,
        referrer_event_line_user_id: direct_line_user.id
      )
      FactoryBot.create(:event_participant, event: event, referrer_shop_id: unlinked_shop.id)
    end

    it "returns acquisition counts for shops linked to event contents" do
      rows = event.admin_shop_acquisition_rows

      expect(rows.map(&:shop)).to contain_exactly(shop)
      expect(rows.first.counts).to eq(direct: 1, indirect: 1, total: 2)
    end
  end

  describe "#analytics_access_counts" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let(:content) { FactoryBot.create(:event_content, :published, event: event) }
    let(:visit) { FactoryBot.create(:ahoy_visit) }
    let(:line_user) { FactoryBot.create(:event_line_user) }
    let(:registered_at) { Time.current }

    before do
      FactoryBot.create(:event_participant, event: event, event_line_user: line_user, registered_at: registered_at)
      create_event_content_view(content, line_user, registered_at - 5.minutes)
      create_event_content_view(content, line_user, registered_at + 5.minutes)
    end

    it "counts PV and UU before and after participant registration" do
      counts = event.analytics_access_counts(content_id: content.id)

      expect(counts[:total]).to eq(pv: 2, uu: 1)
      expect(counts[:before_registration]).to eq(pv: 1, uu: 1)
      expect(counts[:after_registration]).to eq(pv: 1, uu: 1)
    end

    it "excludes exhibitor content views from access counts" do
      exhibitor_shop = FactoryBot.create(:shop)
      FactoryBot.create(:event_content, :unpublished, :booth, event: event, shop: exhibitor_shop)
      exhibitor_line_user = FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_shop.user_id)
      create_event_content_view(content, exhibitor_line_user, registered_at + 10.minutes)

      expect(event.analytics_access_counts(content_id: content.id)[:total]).to eq(pv: 2, uu: 1)
    end

    def create_event_content_view(content, line_user, time)
      Ahoy::Event.create!(
        visit: visit,
        name: "event_content_view",
        properties: {
          event_content_id: content.id.to_s,
          event_line_user_id: line_user.id.to_s
        },
        time: time
      )
    end
  end
end
