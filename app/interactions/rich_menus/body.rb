module RichMenus
  class Body < ActiveInteraction::Base
    string :internal_name
    string :bar_label
    string :layout_type # a, b etc...
    array :actions do
      hash do
        string :type # message, uri
        string :value
        string :desc, default: nil
      end
    end
    string :key

    LAYOUT_TYPES = {
      # a
      # 2500x1686
      # | 1 | 2 | 3 |
      # | 4 | 5 | 6 |
      a: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 833, "height": 843 },
          { "x": 834, "y": 0, "width": 833, "height": 843 },
          { "x": 1667, "y": 0, "width": 833, "height": 843 },
          { "x": 0, "y": 843, "width": 833, "height": 843 },
          { "x": 834, "y": 843, "width": 833, "height": 843 },
          { "x": 1667, "y": 843, "width": 833, "height": 843 }
        ]
      },
      # b
      # 2500x1686
      # | 1 | 2 |
      # | 3 | 4 |
      b: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 1250, "height": 843 },
          { "x": 1251, "y": 0, "width": 1250, "height": 843 },
          { "x": 0, "y": 843, "width": 1250, "height": 843 },
          { "x": 1251, "y": 843, "width": 1250, "height": 843 }
        ]
      },
      # c
      # 2500x1686
      # |     1     |
      # | 2 | 3 | 4 |
      c: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 2500, "height": 843 },
          { "x": 0, "y": 843, "width": 833, "height": 843 },
          { "x": 834, "y": 843, "width": 833, "height": 843 },
          { "x": 1667, "y": 843, "width": 833, "height": 843 }
        ]
      },
      # d
      # 2500x1686
      # |   1   | 2 |
      # |       | 3 |
      d: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 1666, "height": 1686 },
          { "x": 1667, "y": 0, "width": 833, "height": 843 },
          { "x": 1667, "y": 843, "width": 833, "height": 843 }
        ]
      },
      # e
      # 2500x1686
      # |   1   |
      # |   2   |
      e: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 2500, "height": 843 },
          { "x": 0, "y": 843, "width": 2500, "height": 843 }
        ]
      },
      # f
      # 2500x1686
      # | 1 | 2 |
      # |   |   |
      f: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 1250, "height": 1686 },
          { "x": 1251, "y": 0, "width": 1250, "height": 1686 }
        ]
      },
      # g
      # 2500x1686
      # |   1   |
      # |       |
      g: {
        size: { "width": 2500, "height": 1686 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 2500, "height": 1686 }
        ]
      },
      # h
      # 2500x843
      # | 1 | 2 | 3 |
      h: {
        size: { "width": 2500, "height": 843 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 833, "height": 843 },
          { "x": 834, "y": 0, "width": 833, "height": 843 },
          { "x": 1667, "y": 0, "width": 833, "height": 843 }
        ]
      },
      # i - 9
      # 2500x843
      # | 1 |   2   |
      i: {
        size: { "width": 2500, "height": 843 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 833, "height": 843 },
          { "x": 834, "y": 0, "width": 1666, "height": 843 },
        ]
      },
      # j - 10
      # 2500x843
      # |   1   | 2 |
      j: {
        size: { "width": 2500, "height": 843 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 1666, "height": 843 },
          { "x": 1667, "y": 0, "width": 833, "height": 843 },
        ]
      },
      # k - 11
      # 2500x843
      # |  1  |  2  |
      k: {
        size: { "width": 2500, "height": 843 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 1250, "height": 843 },
          { "x": 1251, "y": 0, "width": 1250, "height": 843 },
        ]
      },
      # L - 12
      # 2500x843
      # |     1     |
      l: {
        size: { "width": 2500, "height": 843 },
        action_bounds: [
          { "x": 0, "y": 0, "width": 2500, "height": 843 }
        ]
      }
    }.freeze

    def execute
      {
        "name": internal_name,
        "chatBarText": bar_label,
        "selected": true,
        "size": LAYOUT_TYPES[layout_type.to_sym][:size],
        "areas": areas
      }
    end

    private

    def areas
      actions.map.with_index do |action, i|
        bounds = LAYOUT_TYPES[layout_type.to_sym][:action_bounds][i]

        action =
          case action[:type]
            # TODO: booking_page for show all booking prices
          when *SocialRichMenu::KEYWORDS
            {
              "type": "message",
              "label": I18n.t("line.bot.keywords.#{action[:type]}"),
              "text": I18n.t("line.bot.keywords.#{action[:type]}")
            }
          when "booking_page", "sale_page"
            LineActions::Uri.template(
              label: action[:type],
              url: action[:value],
              key: key
            )
          when "text"
            {
              "type": "message",
              "label": action[:value].first(LineActions::Uri::LABEL_LIMIT),
              "text": action[:value]
            }
          when "uri"
            LineActions::Uri.template(
              label: action[:desc] || action[:value],
              url: action[:value],
              key: key
            )
          end

        {
          "bounds": bounds,
          "action": action
        }
      end
    end
  end
end
