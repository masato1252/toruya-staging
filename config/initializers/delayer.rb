# frozen_string_literal: true

require "active_interaction_delayer"
require "retry"

ActiveInteraction::Base.extend(ActiveInteractionDelayer)
ActiveInteraction::Base.include(Retry)

Delayed::Worker.queue_attributes = {
  high_priority: { priority: 1 },
  default: { priority: 10 },
  message_queue: { priority: 15 },
  low_priority: { priority: 30 },
}

# Set the maximum time (in seconds) a job can run before it is automatically killed
# If a job exceeds this time limit, it will be marked as failed
Delayed::Worker.max_run_time = 120.minutes # Adjust this value based on your needs
Delayed::Worker.max_attempts = 3 # Default is 25

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        before_validation :set_signature
        validates :signature, uniqueness: true, allow_nil: true

        def set_signature
          self.signature = argument_signature
        end

        private

        def argument_signature
          Digest::MD5.hexdigest(YAML.load(handler).job_data["arguments"].to_json)
        end
      end
    end
  end
end
