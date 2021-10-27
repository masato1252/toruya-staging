# frozen_string_literal: true

class ChapterSerializer
  include JSONAPI::Serializer
  attribute :id, :name

  attribute :lessons do |chapter|
    chapter.lessons.order("id").map do |lesson|
      LessonSerializer.new(lesson, { fields: { lesson: [:id, :name] } }).attributes_hash
    end
  end
end
