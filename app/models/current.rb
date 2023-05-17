class Current < ActiveSupport::CurrentAttributes
  attribute :user, :business_owner, :mixpanel_extra_properties, :customer
end
