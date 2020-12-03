module LineActions
  class Postback
    LABEL_LIMIT = 20

    attr_reader :action, :enabled, :params, :displayText

    def initialize(action: , enabled: , params: {}, displayText: true)
      @action = action
      @enabled = enabled
      @params = params
      @displayText = displayText
    end

    def self.template(action: , enabled: , params: {}, displayText: true)
      new(action: action, enabled: enabled, params: params, displayText: displayText).template
    end

    def template
      data = { action: action }.merge(params)

      h = {
        "type": "postback",
        "label": I18n.t("line.actions.label.#{action}").first(LABEL_LIMIT),
        "data": URI.encode_www_form(data),
      }

      h.merge!({ "displayText": I18n.t("line.actions.label.#{action}") }) if displayText

      h
    end
  end
end
