# frozen_string_literal: true

require "utils"

namespace :consultant do
  task :business_health_check do
    # send a slack message to let me know the task is running
    if (Rails.configuration.x.env.production? && Time.current.to_date.monday?)
      SlackClient.send(channel: 'development', text: "Business health check task is running")

      Subscription.charge_required.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: subscription)
      end

      User.business_active.includes(:subscription).find_each do |user|
        if user.subscription&.in_free_plan?
          BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: user.subscription)
        end
      end
    end
  end
end
