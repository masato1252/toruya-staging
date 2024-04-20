class Current < ActiveSupport::CurrentAttributes
  attribute :user, :business_owner, :social_user, :mixpanel_extra_properties, :customer, :device_detector, :admin_debug
end
