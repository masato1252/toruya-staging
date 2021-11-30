# frozen_string_literal: true

class CourseSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :slug

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.company).attributes_hash
  end

  attribute :chapters do |online_service, params|
    online_service.chapters.order("id").includes(:lessons).map do |chapter|
      ChapterSerializer.new(chapter, params: params).attributes_hash
    end
  end

  attribute :lessons do |online_service, params|
    online_service.lessons.order("id").map do |chapter|
      LessonSerializer.new(chapter, params: params).attributes_hash
    end
  end
end
