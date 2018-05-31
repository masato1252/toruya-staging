module Shops
  class Create < ActiveInteraction::Base
    object :user
    hash :params, strip: false

    def execute
      Shop.transaction do
        shop = user.shops.create(params)

        if shop.new_record?
          errors.merge!(shop.errors)
        else
          outcome = Staffs::CreateOwner.run(user: user)

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
