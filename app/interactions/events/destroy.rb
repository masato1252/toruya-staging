# frozen_string_literal: true

module Events
  class Destroy < ActiveInteraction::Base
    object :event

    def execute
      event.soft_delete!
    end
  end
end
