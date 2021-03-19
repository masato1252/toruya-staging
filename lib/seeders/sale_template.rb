# frozen_string_literal: true

module Seeders
  class SaleTemplate
    def self.seed!
      ::SaleTemplate.create(
        edit_body: [
          { component: "input", name: "target", placeholder: "ターゲット", title: "この販売ページのターゲットは誰ですか？", type: "text" },
          { component: "word", content: "の" },
          { component: "input", type: "text", name: "problem", placeholder: "悩み", title: "ターゲットの悩みは何ですか？" },
          { component: "word", content: "を" },
          { component: "br" },
          { component: "input", type: "text", name: "result", placeholder: "解決後の状態", title: "この商品を利用することで\n悩みが解決されたターゲットは\nどんな未来を手に入れられますか？", font_size: "22px" },
          { component: "word", content: "にする" },
          { component: "br" },
          { component: "word", tag: "h4", name: "product_name", font_size: "24px" }
        ],
        view_body: [
          { component: "word", name: "target" },
          { component: "word", content: "の", tag: "span" },
          { component: "word", name: "problem" },
          { component: "word", content: "を", tag: "span" },
          { component: "br" },
          { component: "word", name: "result", color: "#C6A654", font_size: "22px", color_editable: true, color_editable_label: "解決後の状態" },
          { component: "word", content: "にする", tag: "span" },
          { component: "br" },
          { component: "word", tag: "h4", name: "product_name", color: "#64B14D", font_size: "24px", color_editable: true, color_editable_label: "商品名" }
        ]
      )

      ::SaleTemplate.create(
        edit_body: [
          { component: "input", type: "text", name: "problem", placeholder: "悩み", title: "ターゲットの悩みは何ですか？" },
          { component: "word", content: "な" },
          { component: "input", name: "target", placeholder: "ターゲット", title: "この販売ページのターゲットは誰ですか？", type: "text" },
          { component: "word", content: "が" },
          { component: "br" },
          { component: "input", type: "text", name: "result", placeholder: "解決後の状態", title: "この商品を利用することで\n悩みが解決されたターゲットは\nどんな未来を手に入れられますか？", font_size: "22px" },
          { component: "word", content: "になる" },
          { component: "br" },
            { component: "word", tag: "h4", name: "product_name", font_size: "24px" }
        ],
        view_body: [
          { component: "word", name: "problem" },
          { component: "word", content: "な", tag: "span" },
          { component: "word", name: "target" },
          { component: "word", content: "が" },
          { component: "br" },
          { component: "word", name: "result", color: "#C6A654", font_size: "22px", color_editable: true, color_editable_label: "解決後の状態" },
          { component: "word", content: "になる", tag: "span" },
          { component: "br" },
          { component: "word", tag: "h4", name: "product_name", color: "#64B14D", font_size: "24px", color_editable: true, color_editable_label: "商品名" }
        ]
      )
    end
  end
end
