# frozen_string_literal: true

module Episodes
  class Watch < ActiveInteraction::Base
    object :customer
    object :episode

    def execute
      relation = episode.online_service.available_online_service_customer_relations.find_by!(customer: customer)
      relation.update(watched_episode_ids: relation.watched_episode_ids.push(episode.id).map(&:to_s).uniq)
      relation
    end
  end
end
