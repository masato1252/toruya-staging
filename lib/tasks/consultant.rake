# frozen_string_literal: true

require "utils"

namespace :consultant do
  task :business_health_check do
    if (Rails.configuration.x.env.production? && Utils.tokyo_current.to_date.monday?)
      Subscription.charge_required.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_later(subscription: subscription)
      end

      Subscription.trial.find_each do |subscription|
        BusinessHealthChecks::Deliver.perform_later(subscription: subscription)
      end
    end
  end
end