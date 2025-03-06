# frozen_string_literal: true

require "slack_client"
require "google/drive"

class UserProfilingJob < ApplicationJob
  queue_as :low_priority

  def perform(profile_id)
    profile = Profile.find(profile_id)

    return if profile.where_know_toruya.blank? && profile.what_main_problem.blank?

    google_worksheet = Google::Drive.spreadsheet(gid: 1913363436)
    new_row_number = google_worksheet.num_rows + 1

    new_row_data = [
      profile.user_id,
      profile.where_know_toruya,
      profile.what_main_problem,
      profile.created_at.to_s(:date)
    ]
    new_row_data.each_with_index do |data, index|
      google_worksheet[new_row_number, index + 1] = data
    end

    google_worksheet.save

    SlackClient.send(channel: 'sayhi', text: "Profiling user usage \n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=1913363436")
  end
end
