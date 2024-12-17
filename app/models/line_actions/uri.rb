# frozen_string_literal: true

module LineActions
  class Uri
    LABEL_LIMIT = 20

    attr_reader :action, :url, :key, :label, :options
    attr_accessor :social_customer

    def initialize(*args)
      @options = args.extract_options!

      @action = @options[:action]
      @url = @options[:url]
      @key = @options[:key]
      @label = @options[:label]
    end

    def self.template(*args)
      new(*args).template
    end

    def template
      line_label = (label || I18n.t("line.actions.label.#{action}")).first(LABEL_LIMIT)
      result = {
        "type": "uri",
        "label": line_label,
        "uri": key ? Rails.application.routes.url_helpers.function_redirect_url(content: url, label: line_label, source_type: "SocialRichMenu", source_id: key, action_type: "url") : url,
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
