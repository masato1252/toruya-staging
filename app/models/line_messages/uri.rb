module LineMessages
  class Uri
    LABEL_LIMIT = 20

    attr_reader :action, :url, :label
    attr_accessor :social_customer

    def initialize(action: nil, url:, label: nil)
      @action = action
      @url = url
      @label = label
    end

    def self.template(action: nil, url:, label: nil)
      new(action: action, url: url, label: label).template
    end

    def template
      {
        "type": "uri",
        "label": (label || I18n.t("line.actions.label.#{action}")).first(LABEL_LIMIT),
        "uri": url,
      }
    end
  end
end
