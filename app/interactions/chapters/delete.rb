module Chapters
  class Delete < ActiveInteraction::Base
    object :chapter

    validate :validate_lessons

    def execute
      chapter.destroy!
    end

    private

    def validate_lessons
      if chapter.lessons.exists?
        errors.add(:chapter, :lessons_exists)
      end
    end
  end
end
