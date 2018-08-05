MoneyRails.configure do |config|
  # set the default currency
  config.default_currency = :jpy
end

class Money
  class FormattingRules
    def localize_formatting_rules(rules)
      if rules[:ja_default_format]
        super
      else
        if currency.iso_code == "JPY" && I18n.locale == :ja
          rules[:symbol] = "¥" unless rules[:symbol] == false
          rules[:symbol_position] = :before
          rules[:symbol_before_without_space] = true
        end
        rules
      end
    end
  end
end
