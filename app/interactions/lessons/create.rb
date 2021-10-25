module Lessons
  class Create < ActiveInteraction::Base
    object :chapter
    string :name
    string :content_url
    string :note
    string :solution_type

    def execute
      lesson = chapter.lessons.create(
        name: name,
        content_url: content_url,
        note: note,
        solution_type: solution_type,
      )

      if lesson.errors.present?
        errors.merge!(lessons.errors)
      end

      lesson
    end
  end
end
