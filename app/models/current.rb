class Current < ActiveSupport::CurrentAttributes
  attribute :user, :business_owner, :social_user,
   :mixpanel_extra_properties, :customer, :device_detector, :admin_debug, :notify_user_customer_reservation_confirmation_message
end
