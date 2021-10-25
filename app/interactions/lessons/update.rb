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
    end

    def execute
      lesson.with_lock do
        case update_attribute
        when "name", "note", "chapter_id"
          lesson.update(attrs.slice(update_attribute))
        when "content_url"
          lesson.update(content_url: attrs["content_url"], solution_type: attrs["solution_type"])
        end

        if lesson.errors.present?
          errors.merge!(lesson.errors)
        end
      end
    end
  end
end
