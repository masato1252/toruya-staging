class AddLocaleToSaleTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_templates, :locale, :string, null: false, default: "ja"
    SaleTemplate.update_all(locale: "ja")

    SaleTemplate.create(
      locale: "tw",
      edit_body: [
        {
          component: "input", 
          type: "text",
          name: "problem",
          placeholder: "目標客戶的煩惱",
          title: "目標客戶有什麼煩惱？"
        },
        {
          component: "br"
        },
        {
          component: "input",
          type: "text", 
          name: "result",
          placeholder: "解決後的狀態",
          title: "使用這個產品後\n煩惱得到解決的客戶\n能獲得什麼樣的未來？",
          font_size: "22px"
        },
        {
          component: "br"
        },
        {
          component: "word",
          tag: "h4",
          name: "product_name",
          font_size: "24px"
        }
      ],
      view_body: [
        {
          component: "word",
          name: "problem"
        },
        {
          component: "br"
        },
        {
          component: "word",
          name: "result",
          color: "#C6A654",
          font_size: "22px",
          color_editable: true,
          color_editable_label: "解決後的狀態"
        },
        {
          component: "br"
        },
        {
          component: "word",
          tag: "h4",
          name: "product_name",
          color: "#64B14D",
          font_size: "24px",
          color_editable: true,
          color_editable_label: "產品名稱"
        }
      ]
    )
  end
end
