# frozen_string_literal: true

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
          "contents": action_templates
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
          "contents": action_templates
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

    def self.content4(title1: , body1:, action_templates:)
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
              "weight": "bold",
              "size": "lg",
              "align": "center",
              "contents": []
            }
          ]
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": body1,
              "align": "start",
              "wrap": true,
              "contents": []
            }
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

    def self.content5(title1: ,title2:, action_templates:)
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

    def self.content6(asset_url: ,title1: ,title2:, title3:, body:, action_templates:)
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

    def self.content7(picture_url: , content_url: ,title1: ,label:, context:, action_templates:)
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
            "label": title1,
            "uri": content_url
          }
        },
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": title1,
              "weight": "bold",
              "size": "lg",
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
                      "text": label,
                      "size": "sm",
                      "color": "#AAAAAA",
                      "flex": 1,
                      "contents": []
                    },
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

    def self.content8(picture_url:, content_url: ,title: , context:, action_templates:)
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
            "label": title,
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
  end
end
