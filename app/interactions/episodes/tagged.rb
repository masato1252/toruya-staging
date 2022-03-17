# frozen_string_literal: true

module Episodes
  class Tagged < ActiveInteraction::Base
    object :online_service
    string :tag, default: nil

    def execute
      scope = online_service.episodes.available
      scope = scope.where(":tag = ANY(tags)", tag: tag) if tag.present?

      scope
    end
  end
end
