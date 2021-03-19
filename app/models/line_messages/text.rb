# frozen_string_literal: true

module LineMessages
  class Text
    TEXT_LIMIT = 5_000

    attr_reader :text

    def initialize(text:)
      @text = text
    end

    def self.template(text:)
      new(text: text).template
    end

    def template
      {
        "type": "text",
        "text": text,
      }
    end
  end
end
