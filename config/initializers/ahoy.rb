class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    if request.params[:social_user_id] || request.cookies[:line_social_user_id_of_customer]
      data[:line_social_user_id_of_customer] = request.params[:social_user_id] || request.cookies[:line_social_user_id_of_customer]
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
