module LineActions
  class Postback
    LABEL_LIMIT = 20

    attr_reader :action, :enabled

    def initialize(action: , enabled: )
      @action = action
      @enabled = enabled
    end

    def self.template(action: , enabled: )
      new(action: action, enabled: enabled).template
    end

    def template
      {
        "type": "postback",
        "label": I18n.t("line.actions.label.#{action}").first(LABEL_LIMIT),
        "data": URI.encode_www_form({ action: action }),
        "displayText": I18n.t("line.actions.label.#{action}")
      }
    end
  end
end
