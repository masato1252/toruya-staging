module LineActions
  class Uri
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
      # label` must not be longer than 20 characters`
      {
        "type": "uri",
        "label": I18n.t("line.actions.label.#{action}"),
        "uri": url,
      }
    end
  end
end
