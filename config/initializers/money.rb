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
          rules[:format] = "%u%n"
        end
        rules
      end
    end

    alias_method :default_localize_formatting_rules, :localize_formatting_rules
    alias_method :localize_formatting_rules, :custom_localize_formatting_rules
  end
end

Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

