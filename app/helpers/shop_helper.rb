module ShopHelper
  def shops_select_component
    react_component("UI.HeaderSelector",
                    { options: shops.map{|s| { value: s.to_param, label: s.name } },
                      selected_option: shop.to_param,
                      is_shop_selector: true
                    },
                    { id: "shop" })
  end

  def staffs_select_component
    react_component("UI.HeaderSelector",
                    { options: staffs.map{ |s| { value: s.to_param, label: s.name } },
                      selected_option: staff.to_param
                    },
                    { id: "staff" })
  end
end
