require "message_encryptor"

class Callbacks::RemindPermissionsController < ActionController::Base
  def create
    # {
    #   :shop_id => 1,
    #   :customer_id => 2
    # }
    raw_data = MessageEncryptor.decrypt(params[:encrypted_data])

    if customer = Customer.find_by(id: raw_data[:customer_id])
      customer.update(remind_permission: true)

      redirect_to shop_path(raw_data[:shop_id]), alert: "Thanks for approving the reminder permission. We would remind you while the reservation is coming. "
    end
  end
end
