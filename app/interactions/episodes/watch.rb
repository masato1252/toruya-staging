# frozen_string_literal: true

module Episodes
  class Watch < ActiveInteraction::Base
    object :customer
    object :episode

    def execute
      relation = episode.online_service.available_online_service_customer_relations.find_by!(customer: customer)
      relation.update(watched_episode_ids: relation.watched_episode_ids.push(episode.id).map(&:to_s).uniq)

      CustomMessage.scenario_of(episode, CustomMessages::Customers::Template::EPISODE_WATCHED).right_away.each do |custom_message|
        Notifiers::Customers::CustomMessages::EpisodeWatched.perform_later(
          custom_message: custom_message,
          receiver: customer
        )
      end
      relation
    end
  end
end
