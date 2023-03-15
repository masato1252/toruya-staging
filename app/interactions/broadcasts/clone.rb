# frozen_string_literal: true

module Broadcasts
  class Clone < ActiveInteraction::Base
    object :broadcast

    def execute
      new_broadcast = broadcast.deep_clone(
        only: [
          :content,
          :query,
          :query_type,
          :recipients_count,
          :user_id
        ]
      )

      new_broadcast.state = :draft
      new_broadcast.save

      new_broadcast
    end
  end
end
