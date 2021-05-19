# frozen_string_literal: true

module Broadcasts
  class Update < ActiveInteraction::Base
    object :broadcast
    hash :params do
      string :content
      hash :query, strip: false
      time :schedule_at, default: nil
    end

    validate :validate_broadcast

    def execute
      broadcast.with_lock do
        if broadcast.draft?
          broadcast.destroy!
          compose(Broadcasts::Create, user: broadcast.user, params: params)
        end
      end
    end

    private

    def validate_broadcast
      unless broadcast.draft?
        errors.add(:broadcast, :invalid_state)
      end
    end
  end
end
