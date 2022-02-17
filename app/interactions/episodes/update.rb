# frozen_string_literal: true

module Episodes
  class Update < ActiveInteraction::Base
    object :episode
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :content_url, default: nil
      string :solution_type, default: nil
      hash :start_time, default: nil do
        string :start_time_date_part, default: nil
      end
      hash :end_time, default: nil do
        string :end_time_date_part, default: nil
      end
      array :tags, default: nil do
        string
      end
    end

    def execute
      episode.with_lock do
        case update_attribute
        when "name", "tags"
          episode.update(attrs.slice(update_attribute))
        when "content_url"
          episode.update(content_url: attrs["content_url"], solution_type: attrs["solution_type"])
        when "start_time"
          episode.update(
            start_at: attrs[:start_time][:start_time_date_part] ? Time.zone.parse(attrs[:start_time][:start_time_date_part]).beginning_of_day : nil
          )
        when "end_time"
          episode.update(
            end_at: attrs[:end_time][:end_time_date_part] ? Time.zone.parse(attrs[:end_time][:end_time_date_part]).end_of_day : nil
          )
        end

        if episode.errors.present?
          errors.merge!(episode.errors)
        end

        episode
      end
    end
  end
end
