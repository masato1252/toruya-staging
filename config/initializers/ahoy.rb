require "message_encryptor"

class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:customer_social_user_id] =
      if request.params[:social_user_id] || request.cookies[:line_social_user_id_of_customer]
        request.params[:social_user_id] || request.cookies[:line_social_user_id_of_customer]
      elsif request.params[:encrypted_social_service_user_id]
        MessageEncryptor.decrypt(request.params[:encrypted_social_service_user_id])
      end

    super(data)
  end
end

# set to true for JavaScript tracking
Ahoy.api = true

# set to true for geocoding
# we recommend configuring local geocoding first
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
Ahoy.job_queue = :low_priority
Ahoy.visit_duration = 16.hours
