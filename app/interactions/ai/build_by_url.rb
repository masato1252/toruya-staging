# frozen_string_literal: true

module Ai
  class BuildByUrl < ActiveInteraction::Base
    string :user_id
    array :urls do
      string
    end

    def execute
      urls.each do |url|
        AiBuildByUrlJob.perform_later(user_id, url)
      end
    end
  end
end
