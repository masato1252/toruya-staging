module LineActions
  class Uri
    LABEL_LIMIT = 20

    attr_reader :action, :url, :label, :options
    attr_accessor :social_customer

    def initialize(*args)
      @options = args.extract_options!

      @action = @options[:action]
      @url = @options[:url]
      @label = @options[:label]
    end

    def self.template(*args)
      new(*args).template
    end

    def template
      result = {
        "type": "uri",
        "label": (label || I18n.t("line.actions.label.#{action}")).first(LABEL_LIMIT),
        "uri": url,
      }

      if options[:btn]
        result = {
          type: "button",
          action: result,
          style: options[:btn]
        }
      end

      result
    end
  end
end
