module Episodes
  class Create < ActiveInteraction::Base
    object :online_service
    string :name
    string :content_url
    string :note, default: nil
    string :solution_type
    array :tags, default: [] do
      string
    end
    hash :start_time, default: nil do
      string :start_time_date_part, default: nil
    end

    def execute
      episode = online_service.episodes.create(
        user_id: online_service.user_id,
        name: name,
        content_url: content_url,
        note: note,
        solution_type: solution_type,
        start_at: start_time[:start_time_date_part] ? Time.zone.parse(start_time[:start_time_date_part]).beginning_of_day : nil,
        tags: tags
      )

      online_service.tags = Array.wrap(online_service.tags).concat(tags).uniq
      online_service.save!

      if episode.errors.present?
        errors.merge!(episode.errors)
      end

      episode
    end
  end
end
