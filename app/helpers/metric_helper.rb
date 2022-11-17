# frozen_string_literal: true

module MetricHelper
  def number_up_or_down(number_change)
    change_class, icon_class =
      if number_change > 0
        ['up', 'fa-caret-up']
      elsif number_change < 0
        ['down', 'fa-caret-down']
      end

    content_tag :div, class: "number-difference #{change_class}" do
      content_tag(:i, nil, class: "fas #{icon_class}") +
      content_tag(:span, number_change.abs)
    end
  end
end
