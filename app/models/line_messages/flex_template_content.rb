# frozen_string_literal: true

require 'line_client'

# https://www.notion.so/gardencities/LINE-feature-362b327e785242668716e365f26ae640#836483afcd7a46e5bde2ff1e9e80f35a
module LineMessages
  class FlexTemplateContent
    def self.two_header_card(title1: ,title2:, action_templates:)
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
            }
          ]
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
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
        "footer": {
          "type": "box",
          "layout": "vertical",
          "contents": action_templates
        },
        "styles": {
          "body": {
            "separator": true
          }
        }
      }
    end

    def self.icon_three_header_body_card(asset_url: ,title1: ,title2:, title3:, body:, action_templates:)
      {
        "type": "bubble",
        "direction": "ltr",
        "header": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "box",
              "layout": "horizontal",
              "contents": [
                {
                  "type": "image",
                  "url": asset_url,
                  "size": "xxs"
                },
                {
                  "type": "text",
                  "text": title1,
                  "weight": "bold",
                  "size": "lg",
                  "flex": 10,
                  "align": "center",
                  "contents": []
                }
              ]
            },
            {
              "type": "text",
              "text": title2,
              "size": "md",
              "align": "center",
              "weight": "regular",
              "color": "#727272"
            },
            {
              "type": "text",
              "text": title3,
              "size": "sm",
              "align": "center",
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
          "layout": "vertical",
          "spacing": "md",
          "contents": action_templates
        },
        "styles": {
          "body": {
            "separator": true
          }
        }
      }
    end

    def self.video_description_card(picture_url:, content_url: ,title: , context:, action_templates:)
      {
        "type": "bubble",
        "hero": {
          "type": "image",
          "url": picture_url,
          "size": "full",
          "aspectRatio": "20:13",
          "aspectMode": "cover",
          "action": {
            "type": "uri",
            "label": title.first(LineClient::BUTTON_TITLE_LIMIT),
            "uri": content_url
          }
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": title,
              "weight": "bold",
              "size": "lg",
              "wrap": true,
              "contents": []
            },
            {
              "type": "box",
              "layout": "vertical",
              "spacing": "sm",
              "margin": "lg",
              "contents": [
                {
                  "type": "box",
                  "layout": "baseline",
                  "spacing": "sm",
                  "contents": [
                    {
                      "type": "text",
                      "text": context,
                      "size": "sm",
                      "color": "#666666",
                      "flex": 5,
                      "wrap": true,
                      "contents": []
                    }
                  ]
                }
              ]
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "flex": 0,
          "spacing": "sm",
          "contents": action_templates
        }
      }
    end

    def self.button_card(action_templates:)
      {
        "type": "bubble",
        "direction": "ltr",
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "md",
          "contents": action_templates
        }
      }
    end

    def self.next_card(action_template:)
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "button",
              "action": action_template,
              "flex": 1,
              "gravity": "center"
            }
          ]
        }
      }
    end

    def self.title_button_card(title:, action_templates:)
      {
        "type": "bubble",
        "direction": "ltr",
        "header": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": title,
              "size": "lg",
              "align": "start",
              "weight": "bold",
              "wrap": true
            },
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "md",
          "contents": action_templates
        }
      }
    end
  end
end
