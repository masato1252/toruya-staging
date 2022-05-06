# frozen_string_literal: true

class PendingReservationsSummaryJob < ApplicationJob
  queue_as :default

  def perform(user_id, start_time, end_time)
    start_time = Time.zone.parse(start_time)
    end_time = Time.zone.parse(end_time)
    user = User.find(user_id)

    Notifiers::Users::PendingReservationsSummary.run(
      receiver: user,
      user: user,
      start_time: start_time,
      end_time: end_time
    )
  end
end
