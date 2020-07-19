module LineMessages
  class FlexTemplateContent
    def self.content1(title1: ,title2:, body:, action_templates:)
      {
        "type": "bubble",
        "direction": "ltr",
        "header": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": title1,
              "size": "lg",
              "align": "start",
              "weight": "bold"
            },
            {
              "type": "text",
              "text": title2,
              "align": "start",
              "weight": "regular",
              "color": "#727272"
            }
          ]
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": body,
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "horizontal",
          "contents": action_template_buttons_contents(action_templates)
        },
        "styles": {
          "body": {
            "separator": true
          }
        }
      }
    end

    def self.content2(title1: ,title2:, action_templates:)
      {
        "type": "bubble",
        "direction": "ltr",
        "header": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": title1,
              "size": "lg",
              "align": "start",
              "weight": "bold"
            },
            {
              "type": "text",
              "text": title2,
              "align": "start",
              "weight": "regular",
              "color": "#727272",
              "wrap": true
            }
          ]
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": action_template_buttons_contents(action_templates)
        },
        "styles": {
          "body": {
            "separator": true
          }
        }
      }
    end

    def self.content3(body1:, body2:)
      {
        "type": "bubble",
        "direction": "ltr",
        "body": {
          "type": "box",
          "layout": "vertical",
          "spacing": "xxl",
          "contents": [
            {
              "type": "text",
              "text": body1,
              "wrap": true
            },
            {
              "type": "text",
              "text": body2,
              "wrap": true
            }
          ]
        }
      }
    end

    def self.action_template_buttons_contents(action_templates)
      action_templates.map do |action_template|
        {
          "type": "button",
          "action": action_template
        }
      end
    end
  end
end
