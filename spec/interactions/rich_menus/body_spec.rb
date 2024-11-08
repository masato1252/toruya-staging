# frozen_string_literal: true

require "rails_helper"

RSpec.describe RichMenus::Body do
  let(:args) do
    {
      internal_name: "foo",
      bar_label: "foo",
      layout_type: layout_type,
      actions: actions,
      key: key
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    let(:key) { "rich_menu_id"}
    let(:layout_type) { "h" }
    let(:actions) do
      [
        {
          type: "incoming_reservations",
          value: "incoming_reservations"
        },
        {
          type: "text",
          value: "foo"
        },
        {
          type: "uri",
          value: "https://foo.com",
          desc: "bar"
        }
      ]
    end

    it "returns expected body" do
      expect(outcome.result).to eq({
        size: {
          "width": 2500,
          "height": 843
        },
        "selected": true,
        "name": "foo",
        "chatBarText": "foo",
        "areas": [
          {
            bounds: {
              "x": 0,
              "y": 0,
              "width": 833,
              "height": 843
            },
            action: {
              "type": "message",
              "label": "全ての予約",
              "text": "全ての予約"
            }
          },
          {
            bounds: {
              "x": 834,
              "y": 0,
              "width": 833,
              "height": 843
            },
            action: {
              "type": "message",
              "label": "foo",
              "text": "foo"
            }
          },
          {
            bounds: {
              "x": 1667,
              "y": 0,
              "width": 833,
              "height": 843
            },
            action: {
              "type": "uri",
              "label": "bar",
              "uri": Rails.application.routes.url_helpers.function_redirect_url(content: "https://foo.com", source_type: "SocialRichMenu", source_id: key, action_type: "url")
            }
          }
        ]
      })
    end
  end
end