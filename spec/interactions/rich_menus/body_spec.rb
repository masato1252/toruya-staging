# frozen_string_literal: true

require "rails_helper"

RSpec.describe RichMenus::Body do
  let(:args) do
    {
      internal_name: "foo",
      bar_label: "foo",
      layout_type: layout_type,
      actions: actions
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    let(:layout_type) { "k" }
    let(:actions) do
      [
        {
          type: "message",
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
              "width": 1250,
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
              "x": 1251,
              "y": 0,
              "width": 1250,
              "height": 843
            },
            action: {
              "type": "uri",
              "label": "bar",
              "uri": "https://foo.com"
            }
          }
        ]
      })
    end
  end
end
