module ShopHelper
  def shops_select_component
    react_component("management/header_selector",
                    { options: shops.map{|s| { value: s.to_param, label: s.name } },
                      selected_option: shop.to_param,
                      is_shop_selector: true
                    },
                    { id: "shop" })
  end

  def staffs_select_component
    react_component("management/header_selector",
                    { options: staffs.map{ |s| { value: s.to_param, label: s.name } },
                      selected_option: staff.to_param
                    },
                    { id: "staff" })
  end

  def shop_logo_url(shop, size)
    if shop.logo.attached?
      @shop_logo_url ||=
        url_for(shop.logo.variant(
          combine_options: {
            resize: "#{size}",
            flatten: true
          }
      ))
    end
  end

  def shop_logo(shop, size, extent: true, image_class: "")
    if shop.logo.attached?
      image_tag(shop_logo_url(shop, size), class: image_class)
    end
  end
end
