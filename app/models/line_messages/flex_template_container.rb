# frozen_string_literal: true

module LineMessages
  class FlexTemplateContainer
    def self.template(altText:, contents: )
      {
        "type": "flex",
        "altText": altText,
        "contents": contents
      }
    end

    def self.carousel_template(altText:, contents: )
      {
        "type": "flex",
        "altText": altText,
        "contents": {
          "type": "carousel",
          "contents": contents
        }
      }
    end
  end
end
