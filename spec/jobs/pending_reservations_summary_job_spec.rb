# frozen_string_literal: true

require "rails_helper"
require "pending_reservations_summary_job"

RSpec.describe PendingReservationsSummaryJob do
  let(:current_time) { Time.zone.local(2018, 6, 19, 20, 59, 59) }
  let(:time_range) { current_time.beginning_of_hour.advance(hours: -12)..current_time.beginning_of_hour.advance(seconds: -1) }
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(current_time)
  end

  describe "#perform" do
    let!(:matched_pending_reservation1) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }
    let(:user) { matched_pending_reservation1.staffs.first.staff_account.user }
    let(:same_user_staff) { FactoryBot.create(:staff, mapping_user: user) }
    let!(:matched_pending_reservation2) { FactoryBot.create(:reservation, :pending, staff_ids: [same_user_staff.id], created_at: Time.zone.local(2018, 6, 19, 19, 59, 59)) }

    let!(:same_user_before_time_range_reservation) { FactoryBot.create(:reservation, :pending, staff_ids: [same_user_staff.id], created_at: Time.zone.local(2018, 6, 19, 7, 59, 59)) }
    let!(:in_time_range_different_user_reservation) { FactoryBot.create(:reservation, :pending, created_at: Time.zone.local(2018, 6, 19, 8, 0, 0)) }
    let!(:same_user_after_time_range_reservation) { FactoryBot.create(:reservation, :pending, staff_ids: [same_user_staff.id], created_at: Time.zone.local(2018, 6, 19, 20, 0, 0)) }
    before { user.update_columns(phone_number: nil) }

    it "send a pending reservation summary mail" do
      # Pending reservations between today 8:00AM ~ today 7:59PM summary email
      expect(Notifiers::Users::PendingReservationsSummary).to receive(:run).and_call_original
      mailer_double = double(deliver_now: true)
      expect(UserMailer).to receive(:with).and_return(double(custom: mailer_double))

      described_class.perform_now(user.id, time_range.first.to_s, time_range.last.to_s)
    end
  end
end
