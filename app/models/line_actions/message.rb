module LineActions
  class Message
    attr_reader :text

    def initialize(text:)
      @text = text
    end

    def self.template(text:)
      new(text: text).template
    end

    def template
      {
        "type": "message",
        "label": text,
        "text": text,
      }
    end
  end
end
