# frozen_string_literal: true

MoneyRails.configure do |config|
  # set the default currency
  config.default_currency = :jpy
end

class Money
  class FormattingRules
    def custom_localize_formatting_rules(rules)
      if rules[:ja_default_format]
        default_localize_formatting_rules(rules)
      else
        if currency.iso_code == "JPY" && I18n.locale == :ja
          rules[:symbol] = "¥" unless rules[:symbol] == false
          rules[:symbol_position] = :before
          rules[:symbol_before_without_space] = true
        end
        rules
      end
    end

    alias_method :default_localize_formatting_rules, :localize_formatting_rules
    alias_method :localize_formatting_rules, :custom_localize_formatting_rules
  end
end
