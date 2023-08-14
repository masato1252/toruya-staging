class ChangeSaleTemplateEditBody < ActiveRecord::Migration[7.0]
  def change
    SaleTemplate.first.update(
      edit_body: [
        { component: "input", name: "target", placeholder: "ターゲット", title: "この宣伝用LPのターゲットは誰ですか？", type: "text" },
        { component: "word", content: "の" },
        { component: "input", type: "text", name: "problem", placeholder: "悩み", title: "ターゲットの悩みは何ですか？" },
        { component: "word", content: "を" },
        { component: "br" },
        { component: "input", type: "text", name: "result", placeholder: "解決後の状態", title: "この商品を利用することで\n悩みが解決されたターゲットは\nどんな未来を手に入れられますか？", font_size: "22px" },
        { component: "word", content: "にする" },
        { component: "br" },
        { component: "word", tag: "h4", name: "product_name", font_size: "24px" }
      ]
    )

    SaleTemplate.second.update(
      edit_body: [
        { component: "input", type: "text", name: "problem", placeholder: "悩み", title: "ターゲットの悩みは何ですか？" },
        { component: "word", content: "な" },
        { component: "input", name: "target", placeholder: "ターゲット", title: "この宣伝用LPのターゲットは誰ですか？", type: "text" },
        { component: "word", content: "が" },
        { component: "br" },
        { component: "input", type: "text", name: "result", placeholder: "解決後の状態", title: "この商品を利用することで\n悩みが解決されたターゲットは\nどんな未来を手に入れられますか？", font_size: "22px" },
        { component: "word", content: "になる" },
        { component: "br" },
        { component: "word", tag: "h4", name: "product_name", font_size: "24px" }
      ]
    )
  end
end
