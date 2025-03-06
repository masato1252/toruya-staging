# frozen_string_literal: true

module Consultants
  class ApplyApplication < ActiveInteraction::Base
    object :user
    array :category, default: nil do
      string
    end
    string :other_category, default: nil
    array :support, default: nil do
      string
    end
    string :other_support, default: nil

    def execute
      google_worksheet = Google::Drive.spreadsheet(gid: 890284)
      new_row_number = google_worksheet.num_rows + 1
      category_sentence = Array.wrap(category).push(other_category.presence).compact.join(", ")
      support_sentence = Array.wrap(support).push(other_support.presence).compact.join(", ")
      new_row_data = [
        %|=HYPERLINK("https://manager.toruya.com/admin/chats?user_id=#{user.id}", #{user.id})|,
        category_sentence,
        support_sentence,
        Rails.configuration.x.env
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end
      google_worksheet.save

      message = <<-EOF
        📋[Consultant Application] user: <#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|#{user.id}>
        category: #{category_sentence}
        support: #{support_sentence}
        <https://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=890284|application sheet>
      EOF
      HiJob.perform_later(message, "consultants")
    end
  end
end
