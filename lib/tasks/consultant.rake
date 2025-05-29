# frozen_string_literal: true

require "slack_client"
require "utils"

namespace :consultant do
  task :business_health_check => :environment do
    # send a slack message to let me know the task is running
    Rollbar.info("Business health check task is running", {
      environment: Rails.configuration.x.env,
      time: Time.current.to_date.monday?
    })
    candidate_users = []

    if (Rails.configuration.x.env.production? && Time.current.to_date.monday?)
      SlackClient.send(channel: 'development', text: "Business health check task is running")

      Subscription.charge_required.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: subscription)
      end

      User.business_active.includes(:subscription).find_each do |user|
        if user.subscription&.in_free_plan?
          BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: user.subscription)
        end

        if !user.premium_member? && user.customer_message_in_a_row?(7, 3)
          candidate_users << user
        end
      end

      candidate_users_message = candidate_users.map do |user|
        "<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|#{user.id}>"
      end.join(", ")

      SlackClient.send(channel: 'reports', text: "Candidate users: #{candidate_users_message}")
    end
  end
end
