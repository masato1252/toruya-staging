# frozen_string_literal: true

module Episodes
  class Search < ActiveInteraction::Base
    object :online_service
    string :keyword

    def execute
      scope = online_service.episodes.available

      scope.where("name ilike :keyword", keyword: "%#{keyword}%")
    end
  end
end
