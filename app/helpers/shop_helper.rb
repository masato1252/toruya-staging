module ShopHelper
  def shops_select_component
    if request.path.match(/shops\/\d+/)
      react_component("UI.ShopsSelect",
                      { shops: shops_select_options,
                        selected_shop: selected_shop_value },
                      { id: "shop", prerender: true })
    end
  end

  private
  def shops_select_options
    shops.map{|s| { value: s.id, label: s.name } }
  end

  def selected_shop_value
    shop.try(:id) || shops.first.try(:id)
  end

  def shop
    @shop
  end
end
