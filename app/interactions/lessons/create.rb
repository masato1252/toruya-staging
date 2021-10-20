module Lessons
  class Create < ActiveInteraction::Base
    object :chapter
    string :name
    hash :content, default: nil do
      string :url, default: nil
    end
    string :note
    string :solution_type

    def execute
      lesson = chapter.lessons.create(
        name: name,
        content: content,
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
