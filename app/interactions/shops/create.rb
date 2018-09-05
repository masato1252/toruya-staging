module Shops
  class Create < ActiveInteraction::Base
    object :user
    hash :params, strip: false
    string :authorize_token, default: nil

    def execute
      Shop.transaction do
        shop = user.shops.new(params)

        if shop.valid?
          if authorize_token.present?
            charge = compose(Subscriptions::ShopFeeCharge, user: user, authorize_token: authorize_token)
          end

          shop.save
          if charge
            charge.details ||= {}
            charge.details.merge!({
              shop_ids: shop.id,
              type: SubscriptionCharge::TYPES[:shop_fee]
            })
            charge.save!
          end
        end

        if shop.new_record?
          errors.merge!(shop.errors)
        else
          outcome = Staffs::CreateOwner.run(user: user)

          staff = outcome.result.staff

          # Owner staff manage the same shops with User
          staff.shop_ids = Shop.where(user: user).pluck(:id)

          if outcome.errors.present?
            errors.merge!(outcome.errors)

            raise ActiveRecord::Rollback
          end
        end

        shop
      end
    end
  end
end
