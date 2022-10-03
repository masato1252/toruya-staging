# frozen_string_literal: true

class ChapterSerializer
  include JSONAPI::Serializer
  attribute :id, :name

  attribute :lessons do |chapter, params|
    chapter.lessons.map do |lesson|
      LessonSerializer.new(lesson, { fields: { lesson: [:id, :name, :customer_start_time, :started_for_customer, :solution_type] }, params: params }).attributes_hash
    end
  end
end
