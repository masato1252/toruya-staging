module Lessons
  class Create < ActiveInteraction::Base
    object :chapter
    string :name
    string :content_url
    string :note, default: nil
    string :solution_type
    hash :start_time, default: nil do
      integer :start_after_days, default: nil
      string :start_time_date_part, default: nil
    end

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
