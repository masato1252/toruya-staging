# frozen_string_literal: true

module LineActions
  class Message
    attr_reader :text, :label, :btn

    def initialize(text:, label: nil, btn: nil)
      @text = text
      @label = label
      @btn = btn
    end

    def self.template(text:, label: nil, btn: nil)
      new(text: text, label: label, btn: btn).template
    end

    def template
      result = {
        "type": "message",
        "label": label || text,
        "text": text || label,
      }

      if btn
        result = {
          type: "button",
          action: result,
          style: btn
        }
      end

      result
    end
  end
end
