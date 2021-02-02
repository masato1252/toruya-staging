# frozen_string_literal: true

module Shops
  class Create < ActiveInteraction::Base
    object :user
    hash :params, strip: false do
      string :name
      string :short_name
      string :zip_code
      string :phone_number, default: nil
      string :email, default: nil
      string :address
      string :website, default: nil
      boolean :holiday_working, default: false
    end
    string :authorize_token, default: nil

    def execute
      Shop.transaction do
        shop = user.shops.create(params)

        if shop.new_record?
          errors.merge!(shop.errors)
        else
          if authorize_token.present?
            compose(Subscriptions::ShopFeeCharge, user: user, shop: shop, authorize_token: authorize_token)
          end

          staff = compose(Staffs::CreateOwner, user: user).staff

          # Owner staff manage the same shops with User
          staff.shop_ids = Shop.where(user: user).active.pluck(:id)
        end

        shop
      end
    end
  end
end
