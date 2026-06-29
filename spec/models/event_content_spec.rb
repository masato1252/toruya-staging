# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventContent, type: :model do
  # コンテンツの公開期間判定 (started? / ended?) は親イベントの開催期間で強制クランプする。
  # - 開催前: 自身の start_at が過去であっても started? は false
  # - 開催終了後: 自身の end_at が未来 / nil であっても ended? は true
  describe "公開期間の event クランプ" do
    describe "#started?" do
      context "イベントが開始前の場合" do
        let(:event) { FactoryBot.create(:event, :pre_event) }

        it "コンテンツ自身の start_at が過去でも false を返す" do
          content = FactoryBot.build(:event_content, event: event, start_at: 1.day.ago)
          expect(content.started?).to eq(false)
        end

        it "コンテンツ自身の start_at が未来でも false を返す" do
          content = FactoryBot.build(:event_content, event: event, start_at: 1.hour.from_now)
          expect(content.started?).to eq(false)
        end
      end

      context "イベントが開催中の場合" do
        let(:event) { FactoryBot.create(:event, :during_event) }

        it "content.start_at が過去なら true" do
          content = FactoryBot.build(:event_content, event: event, start_at: 1.hour.ago)
          expect(content.started?).to eq(true)
        end

        it "content.start_at が未来なら false" do
          content = FactoryBot.build(:event_content, event: event, start_at: 1.hour.from_now)
          expect(content.started?).to eq(false)
        end

        it "content.start_at が nil なら false (公開開始日時未指定)" do
          content = FactoryBot.build(:event_content, event: event, start_at: nil)
          expect(content.started?).to eq(false)
        end
      end

      context "イベントが終了済の場合" do
        let(:event) { FactoryBot.create(:event, :ended) }

        it "content.start_at が過去であっても (イベントは終わっているが) start 判定自体は true (= 過去のスナップ)" do
          content = FactoryBot.build(:event_content, event: event, start_at: 10.days.ago)
          expect(content.started?).to eq(true)
        end
      end
    end

    describe "#ended?" do
      context "イベントが開始前の場合" do
        let(:event) { FactoryBot.create(:event, :pre_event) }

        it "content.end_at が過去でも (= 矛盾入力) false を返す" do
          content = FactoryBot.build(:event_content, event: event, end_at: 1.hour.ago)
          expect(content.ended?).to eq(false)
        end
      end

      context "イベントが開催中の場合" do
        let(:event) { FactoryBot.create(:event, :during_event) }

        it "content.end_at が過去なら true" do
          content = FactoryBot.build(:event_content, event: event, end_at: 1.hour.ago)
          expect(content.ended?).to eq(true)
        end

        it "content.end_at が未来なら false" do
          content = FactoryBot.build(:event_content, event: event, end_at: 1.hour.from_now)
          expect(content.ended?).to eq(false)
        end

        it "content.end_at が nil なら false (公開終了日時未指定 = 終わらない)" do
          content = FactoryBot.build(:event_content, event: event, end_at: nil)
          expect(content.ended?).to eq(false)
        end
      end

      context "イベントが終了済の場合" do
        let(:event) { FactoryBot.create(:event, :ended) }

        it "content.end_at が未来でも true を返す (イベント終了でクランプ)" do
          content = FactoryBot.build(:event_content, event: event, end_at: 10.days.from_now)
          expect(content.ended?).to eq(true)
        end

        it "content.end_at が nil でも true を返す" do
          content = FactoryBot.build(:event_content, event: event, end_at: nil)
          expect(content.ended?).to eq(true)
        end
      end
    end
  end

  describe "#effective_start_at" do
    context "event.start_at と content.start_at が両方とも存在する場合" do
      it "より遅い方 (max) を返す: event の方が遅いとき" do
        event   = FactoryBot.create(:event, start_at: Time.zone.parse("2026-06-01 10:00"), end_at: Time.zone.parse("2026-06-30 10:00"))
        content = FactoryBot.build(:event_content, event: event, start_at: Time.zone.parse("2026-05-01 10:00"))
        expect(content.effective_start_at).to eq(Time.zone.parse("2026-06-01 10:00"))
      end

      it "より遅い方 (max) を返す: content の方が遅いとき" do
        event   = FactoryBot.create(:event, start_at: Time.zone.parse("2026-06-01 10:00"), end_at: Time.zone.parse("2026-06-30 10:00"))
        content = FactoryBot.build(:event_content, event: event, start_at: Time.zone.parse("2026-06-10 10:00"))
        expect(content.effective_start_at).to eq(Time.zone.parse("2026-06-10 10:00"))
      end
    end

    it "event.start_at が nil なら content.start_at をそのまま返す" do
      event   = FactoryBot.create(:event, start_at: nil, end_at: 7.days.from_now)
      content = FactoryBot.build(:event_content, event: event, start_at: Time.zone.parse("2026-06-10 10:00"))
      expect(content.effective_start_at).to eq(Time.zone.parse("2026-06-10 10:00"))
    end

    it "content.start_at が nil なら event.start_at をそのまま返す" do
      event   = FactoryBot.create(:event, start_at: Time.zone.parse("2026-06-01 10:00"), end_at: 30.days.from_now)
      content = FactoryBot.build(:event_content, event: event, start_at: nil)
      expect(content.effective_start_at).to eq(Time.zone.parse("2026-06-01 10:00"))
    end
  end

  describe "#effective_end_at" do
    context "event.end_at と content.end_at が両方とも存在する場合" do
      it "より早い方 (min) を返す: event の方が早いとき" do
        event   = FactoryBot.create(:event, start_at: Time.zone.parse("2026-06-01 10:00"), end_at: Time.zone.parse("2026-06-30 10:00"))
        content = FactoryBot.build(:event_content, event: event, end_at: Time.zone.parse("2026-07-31 10:00"))
        expect(content.effective_end_at).to eq(Time.zone.parse("2026-06-30 10:00"))
      end

      it "より早い方 (min) を返す: content の方が早いとき" do
        event   = FactoryBot.create(:event, start_at: Time.zone.parse("2026-06-01 10:00"), end_at: Time.zone.parse("2026-06-30 10:00"))
        content = FactoryBot.build(:event_content, event: event, end_at: Time.zone.parse("2026-06-20 10:00"))
        expect(content.effective_end_at).to eq(Time.zone.parse("2026-06-20 10:00"))
      end
    end

    it "event.end_at が nil なら content.end_at をそのまま返す" do
      event   = FactoryBot.create(:event, start_at: 1.day.ago, end_at: nil)
      content = FactoryBot.build(:event_content, event: event, end_at: Time.zone.parse("2026-06-20 10:00"))
      expect(content.effective_end_at).to eq(Time.zone.parse("2026-06-20 10:00"))
    end

    it "content.end_at が nil なら event.end_at をそのまま返す" do
      event   = FactoryBot.create(:event, start_at: 1.day.ago, end_at: Time.zone.parse("2026-06-30 10:00"))
      content = FactoryBot.build(:event_content, event: event, end_at: nil)
      expect(content.effective_end_at).to eq(Time.zone.parse("2026-06-30 10:00"))
    end
  end

  describe "#exhibitor_stats_for" do
    let(:event) { FactoryBot.create(:event, :during_event) }
    let(:exhibitor_user) { FactoryBot.create(:user) }
    let(:exhibitor_shop) { FactoryBot.create(:shop, user: exhibitor_user) }
    let(:other_user) { FactoryBot.create(:user) }
    let(:other_shop) { FactoryBot.create(:shop, user: other_user) }
    let(:exhibitor_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: exhibitor_user.id) }
    let(:other_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: other_user.id) }
    let(:plain_line_user) { FactoryBot.create(:event_line_user, toruya_user_id: FactoryBot.create(:user).id) }
    let(:online_service) { FactoryBot.create(:online_service, user: exhibitor_user) }
    let!(:booth) do
      FactoryBot.create(
        :event_content, :published, :booth,
        event: event, shop: exhibitor_shop, online_service: online_service
      )
    end
    let(:visit) { FactoryBot.create(:ahoy_visit) }

    before do
      Ahoy::Event.create!(
        visit: visit,
        name: "event_content_view",
        properties: { event_content_id: booth.id.to_s, event_line_user_id: plain_line_user.id.to_s },
        time: Time.current
      )
      FactoryBot.create(
        :event_participant,
        event: event,
        event_line_user: plain_line_user,
        referrer_shop_id: exhibitor_shop.id,
        registered_at: Time.current
      )
    end

    it "returns access and acquisition counts for the booth shop owner on a published material-download booth" do
      stats = booth.exhibitor_stats_for(exhibitor_line_user)

      expect(stats).to eq(access_pv: 1, access_uu: 1, acquisition_count: 1)
    end

    it "returns nil for unpublished booth" do
      booth.update!(status: :unpublished)

      expect(booth.exhibitor_stats_for(exhibitor_line_user)).to be_nil
    end

    it "returns nil for seminar content" do
      seminar = FactoryBot.create(:event_content, :published, event: event, shop: exhibitor_shop)

      expect(seminar.exhibitor_stats_for(exhibitor_line_user)).to be_nil
    end

    it "returns nil for other exhibitor" do
      FactoryBot.create(:event_content, :published, :booth, event: event, shop: other_shop, online_service: online_service)

      expect(booth.exhibitor_stats_for(other_line_user)).to be_nil
    end

    it "returns nil for general users" do
      expect(booth.exhibitor_stats_for(plain_line_user)).to be_nil
    end

    it "returns nil when line_user is nil" do
      expect(booth.exhibitor_stats_for(nil)).to be_nil
    end
  end
end
