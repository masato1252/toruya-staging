# frozen_string_literal: true

module Ai
  class Build < ActiveInteraction::Base
    string :user_id
    array :urls do
      string
    end

    def execute
      AI_BUILD.perform(user_id, urls)
    end
  end
end
