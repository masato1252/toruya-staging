module Chapters
  class Update < ActiveInteraction::Base
    object :chapter
    string :name

    def execute
      chapter.update(name: name)
      chapter
    end
  end
end
