module Shops
  class Delete < ActiveInteraction::Base
    object :user
    object :shop

    def execute
      if shop.update(deleted_at: Time.current)
        if (staff_account = user.current_staff_account(user)) && staff_account.owner?
          staff = staff_account.staff

          # Owner staff could manage the same shops with User
          staff.shop_ids = user.shop_ids
          staff.save
          return
        end
      else
        errors.add(:shop, :delete_failed)
      end
    end
  end
end
