module LineActions
  class Message
    attr_reader :text, :label

    def initialize(text:, label: nil)
      @text = text
      @label = label
    end

    def self.template(text:, label: nil)
      new(text: text, label: label).template
    end

    def template
      {
        "type": "message",
        "label": label || text,
        "text": text,
      }
    end
  end
end
