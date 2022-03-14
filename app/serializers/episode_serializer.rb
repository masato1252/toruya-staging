# frozen_string_literal: true

class EpisodeSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :solution_type, :start_time, :end_time, :online_service_id, :tags, :thumbnail_url, :note

  attribute :content_url, if: Proc.new { |episode, params|
    params[:is_owner] || episode.started?
  }

  attribute :available do |episode|
    episode.available?
  end
end
