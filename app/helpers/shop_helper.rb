module ShopHelper
  def shops_select_options
    shops.map{|s| { value: settings_shop_path(s), label: s.name } if s.persisted? }.compact
  end

  def selected_shop_path
    if shop.persisted?
      settings_shop_path(shop)
    elsif shops.present?
      settings_shop_path(shops.first)
    end
  end

  def shop
    @shop
  end
end
