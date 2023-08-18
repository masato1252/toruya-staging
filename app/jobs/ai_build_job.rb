# frozen_string_literal: true

class AiBuildJob < ApplicationJob
  queue_as :default

  def perform(user_id, url)
    AI_BUILD.perform(user_id, url)
  end
end
