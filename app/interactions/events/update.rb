# frozen_string_literal: true

module Events
  class Update < ActiveInteraction::Base
    object :event

    string :title, default: nil
    string :slug, default: nil
    string :description, default: nil
    string :start_at, default: nil
    string :end_at, default: nil
    boolean :published, default: nil

    def execute
      attrs = {
        title: title,
        description: description,
        start_at: start_at.presence,
        end_at: end_at.presence
      }
      attrs[:slug] = slug.downcase.strip if slug.present?
      attrs[:published] = published unless published.nil?

      unless event.update(attrs.compact)
        errors.merge!(event.errors)
      end

      event
    end
  end
end
