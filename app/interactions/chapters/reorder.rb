module Chapters
  class Reorder < ActiveInteraction::Base
    object :online_service
    array :items do
      hash do
        integer :id
        array :lessons, default: [] do
          integer
        end
      end
    end

    def execute
      chapters = online_service.chapters
      lessons = online_service.lessons

      items.each.with_index do |args, position|
        chapter = chapters.find { |chapter| chapter.id == args[:id] }
        chapter.update(position: position)

        args[:lessons].each.with_index do |lesson_id, lesson_position|
          lesson = lessons.find { |lesson| lesson.id == lesson_id }
          lesson.update(position: lesson_position, chapter_id: chapter.id)
        end
      end
    end
  end
end
