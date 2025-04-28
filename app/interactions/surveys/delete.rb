# frozen_string_literal: true

module Surveys
  class Delete < ActiveInteraction::Base
    object :survey

    def execute
      if survey.responses.any?
        survey.update(deleted_at: Time.current)
        # clean all the future reservations

        reservations = Reservation.where(survey_activity_id: survey.activity_ids).where("start_time > ?", Time.current)
        reservations.update_all(deleted_at: Time.current)
        survey.user.booking_pages.each do |booking_page|
          reservations.each do |reservation|
            ::Booking::Cache.perform_later(booking_page: booking_page, date: reservation.start_time.to_date)
          end
        end
      else
        survey.destroy
      end
    end
  end
end
