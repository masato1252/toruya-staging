# frozen_string_literal: true

module Episodes
  class Search < ActiveInteraction::Base
    object :online_service
    string :keyword, default: nil
    boolean :available, default: true

    def execute
      scope = online_service.episodes.order("id DESC")

      scope = scope.available if available
      scope = scope.where("name ilike :keyword", keyword: "%#{keyword}%") if keyword.present?
      scope
    end
  end
end
