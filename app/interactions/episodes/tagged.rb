# frozen_string_literal: true

module Episodes
  class Tagged < ActiveInteraction::Base
    ALL = 'all'

    object :online_service
    string :tag

    def execute
      scope = online_service.episodes.available

      if tag != ALL
        scope = scope.where(":tag = ANY(tags)", tag: tag)
      end

      scope
    end
  end
end
