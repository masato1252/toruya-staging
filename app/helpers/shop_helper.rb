# frozen_string_literal: true

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

  def shop_logo_url(shop, size, latest = false)
    @shop_logo_urls ||= {}

    if shop.logo.attached?
      if latest
        Images::Process.run!(image: shop.logo, resize: "#{size}")
      else
        @shop_logo_urls["#{shop.class.name}_#{shop.id}_#{size}"] ||= Images::Process.run!(image: shop.logo, resize: "#{size}")
      end
    end
  end

  def staff_picture_url(staff, size)
    Images::Process.run!(image: staff.picture, resize: "#{size}") if staff.picture.attached?
  end

  def shop_logo(shop, size, extent: true, image_class: "")
    if shop.logo.attached? && (url = shop_logo_url(shop, size))
      image_tag(url, class: image_class)
    end
  end
end
