# frozen_string_literal: true

class LessonSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :note, :solution_type, :chapter_id, :content_url

  attribute :online_service_id do |lesson|
    lesson.chapter.online_service_id
  end
end
