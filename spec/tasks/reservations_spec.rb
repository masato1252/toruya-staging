# frozen_string_literal: true

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
      expect(PendingReservationsSummaryJob).not_to receive(:perform_later)

      task.execute
    end
  end

  context "when current time is Japan 8AM" do
    let(:current_time) { Time.zone.local(2018, 6, 19, 8, 59, 59) }

    context "when there are users who have pending reservations between yesterday 8:00PM ~ today 7:59AM(20:00 ~ 7:59)" do
      let!(:unmatched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 18, 19, 59, 59)) }
      let!(:matched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 18, 20, 0, 0)) }
      let(:same_user_staff) { FactoryBot.create(:staff, mapping_user: matched_pending_reservation1.staffs.first.staff_account.user) }
      let!(:matched_pending_reservation1_1) { FactoryBot.create(:reservation, :pending, staffs: same_user_staff, created_at: Time.zone.local(2018, 6, 18, 20, 0, 0)) }
      let!(:matched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
      let(:same_staffs) { matched_pending_reservation2.staffs }
      let!(:matched_pending_reservation2_1) { FactoryBot.create(:reservation, :pending, staffs: same_staffs , created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
      let!(:unmatched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }

      it "sends the jobs to the active staff_account's users" do
        expect(PendingReservationsSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation1.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once
        expect(PendingReservationsSummaryJob).to receive(:perform_later).
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
      let!(:matched_pending_reservation1_1) { FactoryBot.create(:reservation, :pending, staffs: same_user_staff, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }
      let!(:matched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 19, 59, 59)) }
      let(:same_staffs) { matched_pending_reservation2.staffs }
      let!(:matched_pending_reservation2_1) { FactoryBot.create(:reservation, :pending, staffs: same_staffs , created_at: Time.zone.local(2018, 6, 19, 19, 59, 59)) }
      let!(:unmatched_pending_reservation2) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 20, 0, 0)) }

      it "sends the jobs to the users" do
        expect(PendingReservationsSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation1.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once
        expect(PendingReservationsSummaryJob).to receive(:perform_later).
          with(matched_pending_reservation2.staffs.first.staff_account.user_id, time_range.first.to_s, time_range.last.to_s).once

        task.execute
      end
    end
  end
end

RSpec.describe "rake reservations:reminder" do
  let(:current_time) { Time.now }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  context "remind paid users' customers before reservations' start time 24 hours" do
    let(:paid_user) { FactoryBot.create(:subscription, :basic).user }
    let(:paid_shop) { FactoryBot.create(:shop, user: paid_user) }
    let!(:paid_reservation_in_time) { FactoryBot.create(:reservation, :reserved, shop: paid_shop, start_time: current_time.advance(hours: 24)) }
    let!(:paid_pending_reservation_in_time) { FactoryBot.create(:reservation, :pending, shop: paid_shop, start_time: current_time.advance(hours: 24)) }
    let!(:paid_reservation_off_time) { FactoryBot.create(:reservation, :reserved, shop: paid_shop, start_time: current_time.advance(hours: 25)) }
    let(:trial_user) { FactoryBot.create(:subscription, :free).user }
    let(:free_shop) { FactoryBot.create(:shop, user: trial_user) }
    let!(:free_reservation_in_time) { FactoryBot.create(:reservation, :reserved, shop: free_shop, start_time: current_time.advance(hours: 24)) }

    it "reminds expected reservations" do
      expect(ReservationReminderJob).to receive(:perform_later).with(paid_reservation_in_time).once
      expect(ReservationReminderJob).to receive(:perform_later).with(free_reservation_in_time).once
      expect(ReservationReminderJob).not_to receive(:perform_later).with(paid_pending_reservation_in_time)
      expect(ReservationReminderJob).not_to receive(:perform_later).with(paid_reservation_off_time)

      task.execute
    end
  end
end
