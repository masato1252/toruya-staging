# frozen_string_literal: true

class AiBuildJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id, url)
    AI_BUILD.perform(user_id, url)
  end
end
