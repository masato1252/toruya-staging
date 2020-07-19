module LineMessages
  class CarouselColumn
    TITLE_LIMIT = 40
    DESCRIPTION_LIMIT = 60

    attr_reader :title, :text, :actions

    def initialize(title:, text:, actions:)
      @title = title
      @text = text
      @actions = actions
    end

    def self.template(title:, text:, actions:)
      new(title: title, text: text, actions: actions).template
    end

    def template
      {
        "title": title.first(TITLE_LIMIT),
        "text": text.first(DESCRIPTION_LIMIT),
        "actions": actions.map(&:template)
      }
    end
  end
end
