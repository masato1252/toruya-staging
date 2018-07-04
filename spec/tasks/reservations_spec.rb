require "rails_helper"
require "pending_reservations_summary_job"

RSpec.describe "rake reservations:pending_notifications" do
  let(:current_time) { Time.now }
  let(:time_range) { current_time.beginning_of_hour.advance(hours: -12)..current_time.beginning_of_hour.advance(seconds: -1) }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  context "when current time is not around Japan 8AM" do
    let(:current_time) { Time.use_zone("Tokyo") { Time.zone.local(2018, 6, 19, 8, 0, 1) } }

    it "do nothing" do
      expect(PendingReservationSummaryJob).not_to receive(:perform_later)

      task.execute
    end
  end

  context "when current time is Japan 8AM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 8, 59, 59) }

    context "when there are users who have pending reservations between yesterday 8:00PM ~ today 7:59AM(20:00 ~ 7:59)" do
      let!(:unmatched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 18, 19, 59, 59)) }
      let!(:matched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 18, 20, 0, 0)) }
      let(:same_user_staff) { FactoryBot.create(:staff, mapping_user: matched_pending_reservation1.staffs.first.staff_account.user) }
      let!(:matched_pending_reservation1_1) { FactoryBot.create(:reservation, :pending, staff_ids: [same_user_staff.id], created_at: Time.zone.local(2018, 6, 18, 20, 0, 0)) }
      let!(:matched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
      let(:same_staffs) { matched_pending_reservation2.staff_ids }
      let!(:matched_pending_reservation2_1) { FactoryBot.create(:reservation, :pending, staff_ids: same_staffs , created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
      let!(:unmatched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }

      it "sends the jobs to the active staff_account's users" do
        expect(PendingReservationSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation1.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once
        expect(PendingReservationSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation2.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once

        task.execute
      end
    end
  end

  context "when current time is Japan 8PM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 20, 59, 59) }

    context "when there are users who have pending reservations between today 8:00AM ~ today 7:59PM(8:00 ~ 19:59)" do
      let!(:unmatched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
      let!(:matched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }
      let(:same_user_staff) { FactoryBot.create(:staff, mapping_user: matched_pending_reservation1.staffs.first.staff_account.user) }
      let!(:matched_pending_reservation1_1) { FactoryBot.create(:reservation, :pending, staff_ids: [same_user_staff.id], created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }
      let!(:matched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 19, 59, 59)) }
      let(:same_staffs) { matched_pending_reservation2.staff_ids }
      let!(:matched_pending_reservation2_1) { FactoryBot.create(:reservation, :pending, staff_ids: same_staffs , created_at: Time.zone.local(2018, 6, 19, 19, 59, 59)) }
      let!(:unmatched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 20, 0, 0)) }

      it "sends the jobs to the users" do
        expect(PendingReservationSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation1.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once
        expect(PendingReservationSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation2.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once

        task.execute
      end
    end
  end
end
