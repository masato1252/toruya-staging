module Chapters
  class Create < ActiveInteraction::Base
    object :online_service
    string :name

    def execute
      chapter = online_service.chapters.create(name: name, position: online_service.chapters.count)
      chapter.save
      chapter
    end
  end
end
