# frozen_string_literal: true

module Broadcasts
  class Update < ActiveInteraction::Base
    object :broadcast
    string :update_attribute
    hash :params do
      string :content, default: nil
      hash :query, strip: false, default: nil
      string :query_type, default: nil
      time :schedule_at, default: nil
    end

    validate :validate_broadcast

    def execute
      broadcast.with_lock do
        if broadcast.draft?
          attributes = broadcast.slice(:content, :query, :query_type, :schedule_at)
          attributes[update_attribute] = params[update_attribute]

          compose(Broadcasts::Create, user: broadcast.user, params: attributes)
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
