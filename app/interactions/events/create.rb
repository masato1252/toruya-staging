# frozen_string_literal: true

module Events
  class Create < ActiveInteraction::Base
    object :user

    string :title
    string :slug
    string :description, default: nil
    string :start_at, default: nil
    string :end_at, default: nil
    boolean :published, default: false

    validates :title, presence: true
    validates :slug, presence: true

    def execute
      event = user.events.build(
        title: title,
        slug: slug.downcase.strip,
        description: description,
        start_at: start_at.presence,
        end_at: end_at.presence,
        published: published
      )

      unless event.save
        errors.merge!(event.errors)
        return
      end

      event
    end
  end
end
