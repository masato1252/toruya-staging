# https://developers.google.com/google-apps/calendar/v3/reference/
class GooglePlusWrapper
  def initialize(current_user)
    configure_client(current_user)
  end

  def configure_client(current_user)
    @client = Google::APIClient.new
    @client.authorization.access_token = current_user.access_provider.access_token
    @client.authorization.refresh_token = current_user.access_provider.refresh_token
    @client.authorization.client_id = ENV['GOOGLE_CLIENT_ID']
    @client.authorization.client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @client.authorization.refresh!
    @service = @client.discovered_api("plus")
  end

  def me
    @client.execute(@service.people.get, :userId => 'me').data
  end
end
