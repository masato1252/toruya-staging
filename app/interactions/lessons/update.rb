# frozen_string_literal: true

module Lessons
  class Update < ActiveInteraction::Base
    object :lesson
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :note, default: nil
      string :content_url, default: nil
      string :solution_type, default: nil
      integer :chapter_id, default: nil
      hash :start_time, default: nil do
        integer :start_after_days, default: nil
        string :start_time_date_part, default: nil
      end
    end

    def execute
      lesson.with_lock do
        case update_attribute
        when "name", "note", "chapter_id"
          lesson.update(attrs.slice(update_attribute))
        when "content_url"
          lesson.update(content_url: attrs["content_url"], solution_type: attrs["solution_type"])
        when "start_time"
          lesson.update(
            start_at: attrs[:start_time][:start_time_date_part] ? Time.zone.parse(attrs[:start_time][:start_time_date_part]).beginning_of_day : nil,
            start_after_days: attrs[:start_time][:start_after_days]
          )
        end

        if lesson.errors.present?
          errors.merge!(lesson.errors)
        end
      end
    end
  end
end
