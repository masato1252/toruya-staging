# frozen_string_literal: true

module MultiShopHelper
  def multi_shop_mode?(owner = Current.business_owner)
    owner.present? && !owner.has_single_shop?
  end
end
