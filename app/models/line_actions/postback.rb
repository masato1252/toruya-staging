module LineActions
  class Postback
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
        "label": I18n.t("line.actions.label.#{action}"),
        "data": URI.encode_www_form({ action: action })
      }
    end
  end
end
