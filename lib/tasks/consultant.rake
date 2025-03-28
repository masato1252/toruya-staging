# frozen_string_literal: true

require "utils"

namespace :consultant do
  task :business_health_check do
    # send a slack message to let me know the task is running
    if (Rails.configuration.x.env.production? && Utils.tokyo_current.to_date.monday?)
      SlackClient.send(channel: 'development', text: "Business health check task is running")

      Subscription.charge_required.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: subscription)
      end

      Subscription.trial.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_at(schedule_at: Time.current.advance(minutes: rand(10)), subscription: subscription)
      end
    end
  end
end
