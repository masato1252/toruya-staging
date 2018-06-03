module Shops
  class Delete < ActiveInteraction::Base
    object :user
    object :shop

    def execute
      if shop.destroy
        if (staff_account = user.current_staff_account(user)) && staff_account.owner?
          staff = staff_account.staff

          # Owner staff could manage the same shops with User
          staff.shop_ids = Shop.where(user: user).pluck(:id)
          staff.save
          return
        end
      end
    end
  end
end
