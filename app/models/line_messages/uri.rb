module LineMessages
  class Uri
    LABEL_LIMIT = 20

    attr_reader :action, :url
    attr_accessor :social_customer

    def initialize(action:, url:)
      @action = action
      @url = url
    end

    def self.template(action:, url:)
      new(action: action, url: url).template
    end

    def template
      {
        "type": "uri",
        "label": I18n.t("line.actions.label.#{action}").first(LABEL_LIMIT),
        "uri": url,
      }
    end
  end
end
