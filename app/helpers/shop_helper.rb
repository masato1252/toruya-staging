module ShopHelper
  def shops_select_component(option_path_method: )
    content_for :shops_select do
      react_component("UI.ShopsSelect",
                      { shops: shops_select_options(option_path_method),
                        selected_shop: selected_shop_path(option_path_method) },
                        { id: "shop", prerender: true })
    end
  end

  private
  def shops_select_options(path_method)
    shops.map{|s| { value: public_send(path_method, s), label: s.name } }
  end

  def selected_shop_path(path_method)
    if shops.present?
      public_send(path_method, shop || shops.first)
    end
  end

  def shop
    @shop
  end
end
