module Chapters
  class Create < ActiveInteraction::Base
    object :online_service
    string :name

    def execute
      chapter = online_service.chapters.create(name: name)
      chapter.save
      chapter
    end
  end
end
