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

  class Currency
    def default_subunit_to_unit
      # Normal money .fractional should already be in the subunit, so default_subunit_to_unit should be 1
      # Currently only TWD needs this
      Money::Currency.table[id][:default_subunit_to_unit] || 1
    end
  end
end

Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

MoneyRails.configure do |config|
  # reference: https://github.com/RubyMoney/money/blob/73b84b5183c19dfa251b4c27c84d120de29d342f/config/currency_iso.json#L957
  config.register_currency = {
    "priority": 100,
    "iso_code": "TWD",
    "name": "New Taiwan Dollar",
    "symbol": "NT$", # original: $
    "disambiguate_symbol": "NT$",
    "alternate_symbols": ["NT$"],
    "subunit": "Cent",
    "subunit_to_unit": 1, # original: 100
    "default_subunit_to_unit": 100,
    "symbol_first": true,
    "html_entity": "$",
    "decimal_mark": ".",
    "thousands_separator": ",",
    "iso_numeric": "901",
    "smallest_denomination": 50
  }
end
