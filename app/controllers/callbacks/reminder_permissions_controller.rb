# frozen_string_literal: true

require "message_encryptor"

class Callbacks::ReminderPermissionsController < ActionController::Base
  skip_before_action :track_ahoy_visit
  def create
    # params[:encrypted_data]
    # {
    #   :shop_id => 1,
    #   :customer_id => 2
    # }
    raw_data = MessageEncryptor.decrypt(params[:encrypted_data])

    if customer = Customer.find_by(id: raw_data[:customer_id])
      customer.update(reminder_permission: true)

      redirect_to shop_path(raw_data[:shop_id])
    end
  end
end
