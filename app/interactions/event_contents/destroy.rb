# frozen_string_literal: true

module EventContents
  class Destroy < ActiveInteraction::Base
    object :event_content

    def execute
      event_content.soft_delete!
    end
  end
end
