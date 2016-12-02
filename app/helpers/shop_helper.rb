module ShopHelper
  def shops_select_component
    if request.path.match(/shops\/\d+/)
      react_component("UI.ShopsSelect",
                      { shops: shops_select_options,
                        selected_shop: selected_shop_value },
                      { id: "shop" })
    end
  end

  private
  def shops_select_options
    shops.map{|s| { value: s.to_param, label: s.name } }
  end

  def selected_shop_value
    shop.try(:to_param) || shops.first.try(:to_param)
  end
end
