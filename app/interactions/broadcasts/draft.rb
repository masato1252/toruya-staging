# frozen_string_literal: true

module Broadcasts
  class Draft < ActiveInteraction::Base
    object :broadcast

    def execute
      broadcast.with_lock do
        if broadcast.active?
          broadcast.draft!
        end
      end
    end
  end
end
