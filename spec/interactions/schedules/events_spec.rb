# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schedules::Events do
  describe "#execute" do
    let(:date) { Date.new(2026, 6, 16) }
    let(:viewer) { FactoryBot.create(:user) }
    let(:other_user) { FactoryBot.create(:user) }

    before do
      create_personal_schedule(viewer, open: true, reason: "本人メモ")
      create_personal_schedule(other_user, open: true, reason: "他人メモ")
      create_personal_schedule(other_user, open: false, reason: "他人ブロック")
    end

    it "returns open personal schedules only for visible users while keeping closed schedules for all users" do
      schedules = described_class.run!(
        working_shop_ids: [],
        user_ids: [viewer.id, other_user.id],
        visible_open_schedule_user_ids: [viewer.id],
        date: date
      )

      expect(schedules[:open_schedules].map(&:reason)).to contain_exactly("本人メモ")
      expect(schedules[:off_schedules].map(&:reason)).to contain_exactly("他人ブロック")
    end

    def create_personal_schedule(user, open:, reason:)
      FactoryBot.create(
        :custom_schedule,
        :personal,
        user: user,
        open: open,
        reason: reason,
        start_time_date_part: date.to_s,
        start_time_time_part: "10:00",
        end_time_time_part: "11:00"
      )
    end
  end
end
