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
        Rails.application.routes.url_helpers.url_for(shop.logo.variant(
          combine_options: {
            resize: "#{size}",
            flatten: true
          }
        ))
      else
        @shop_logo_urls[shop.id] ||=
          Rails.application.routes.url_helpers.url_for(shop.logo.variant(
            combine_options: {
              resize: "#{size}",
              flatten: true
            }
        ))
      end
    end
  end

  def staff_picture_url(staff, size)
    @staff_picture_urls ||= {}

    if staff.picture.attached?
      @staff_picture_urls[staff.id] ||=
        Rails.application.routes.url_helpers.url_for(staff.picture.variant(
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
