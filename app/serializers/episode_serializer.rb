# frozen_string_literal: true

class EpisodeSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :solution_type, :start_time, :end_time, :online_service_id, :tags

  attribute :content_url, if: Proc.new { |episode, params|
    params[:is_owner] || episode.started?
  }
end
