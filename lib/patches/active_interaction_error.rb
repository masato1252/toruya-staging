module ActiveModel
  class Error
    def full_message
      return message if attribute == :base
      attr_name = attribute.to_s.tr('.', '_').humanize
      attr_name = @base.class.human_attribute_name(attribute, default: attr_name)

      if message.start_with?('^')
        I18n.t("errors.format", attribute: '', message: message[1..-1])
      else
        I18n.t("errors.format", attribute: attr_name, message: message )
      end
    end
  end
end
